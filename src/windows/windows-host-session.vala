#if WINDOWS
namespace Frida {
	public class WindowsHostSessionBackend : Object, HostSessionBackend {
		private WindowsHostSessionProvider local_provider;

		public async void start () {
			assert (local_provider == null);
			local_provider = new WindowsHostSessionProvider ();
			provider_available (local_provider);
		}

		public async void stop () {
			assert (local_provider != null);
			provider_unavailable (local_provider);
			yield local_provider.close ();
			local_provider = null;
		}
	}

	public class WindowsHostSessionProvider : Object, HostSessionProvider {
		public string name {
			get { return "Local System"; }
		}

		public ImageData? icon {
			get { return _icon; }
		}
		private ImageData? _icon;

		public HostSessionProviderKind kind {
			get { return HostSessionProviderKind.LOCAL_SYSTEM; }
		}

		private WindowsHostSession host_session;

		construct {
			try {
				_icon = _extract_icon ();
			} catch (Error e) {
			}
		}

		public async void close () {
			if (host_session != null)
				yield host_session.close ();
			host_session = null;
		}

		public async HostSession create (string? location = null) throws Error {
			assert (location == null);
			if (host_session != null)
				throw new Error.INVALID_ARGUMENT ("Invalid location: already created");
			host_session = new WindowsHostSession ();
			host_session.agent_session_closed.connect (on_agent_session_closed);
			return host_session;
		}

		public async void destroy (HostSession session) throws Error {
			if (session != host_session)
				throw new Error.INVALID_ARGUMENT ("Invalid host session");
			host_session.agent_session_closed.disconnect (on_agent_session_closed);
			yield host_session.close ();
			host_session = null;
		}

		public async AgentSession obtain_agent_session (HostSession host_session, AgentSessionId agent_session_id) throws Error {
			if (host_session != this.host_session)
				throw new Error.INVALID_ARGUMENT ("Invalid host session");
			return yield this.host_session.obtain_agent_session (agent_session_id);
		}

		private void on_agent_session_closed (AgentSessionId id, AgentSession session) {
			agent_session_closed (id);
		}

		public static extern ImageData? _extract_icon () throws Error;
	}

	public class WindowsHostSession : BaseDBusHostSession {
		private ProcessEnumerator process_enumerator = new ProcessEnumerator ();

		public Gee.HashMap<uint, void *> instance_by_pid = new Gee.HashMap<uint, void *> ();

		private Winjector winjector = new Winjector ();
		private AgentDescriptor agent_desc;

		construct {
			var blob32 = Frida.Data.Agent.get_frida_agent_32_dll_blob ();
			var blob64 = Frida.Data.Agent.get_frida_agent_64_dll_blob ();
			var dbghelp32 = Frida.Data.Agent.get_dbghelp_32_dll_blob ();
			var dbghelp64 = Frida.Data.Agent.get_dbghelp_64_dll_blob ();
			agent_desc = new AgentDescriptor.with_resources ("frida-agent-%u.dll",
				new MemoryInputStream.from_data (blob32.data, null),
				new MemoryInputStream.from_data (blob64.data, null),
				new AgentResource[] {
					new AgentResource ("dbghelp-32.dll", new MemoryInputStream.from_data (dbghelp32.data, null)),
					new AgentResource ("dbghelp-64.dll", new MemoryInputStream.from_data (dbghelp64.data, null))
				}
			);
		}

		public override async void close () {
			yield base.close ();

			/* HACK: give processes 100 ms to unload DLLs */
			var source = new TimeoutSource (100);
			source.set_callback (() => {
				close.callback ();
				return false;
			});
			source.attach (MainContext.get_thread_default ());
			yield;

			agent_desc = null;

			yield winjector.close ();
			winjector = null;
		}

		public override async HostProcessInfo[] enumerate_processes () throws Error {
			return yield process_enumerator.enumerate_processes ();
		}

		public override async uint spawn (string path, string[] argv, string[] envp) throws Error {
			return _do_spawn (path, argv, envp);
		}

		public override async void resume (uint pid) throws Error {
			void * instance;
			bool instance_found = instance_by_pid.unset (pid, out instance);
			if (!instance_found)
				throw new Error.INVALID_ARGUMENT ("Invalid pid");
			_resume_instance (instance);
			_free_instance (instance);
		}

		public override async void kill (uint pid) throws Error {
			void * instance;
			bool instance_found = instance_by_pid.unset (pid, out instance);
			if (instance_found)
				_free_instance (instance);
			System.kill (pid);
		}

		protected override async IOStream perform_attach_to (uint pid, out Object? transport) throws Error {
			PipeTransport t;
			Pipe stream;
			try {
				t = new PipeTransport ();
				stream = new Pipe (t.local_address);
			} catch (IOError stream_error) {
				throw new Error.NOT_SUPPORTED (stream_error.message);
			}
			yield winjector.inject (pid, agent_desc, t.remote_address);
			transport = t;
			return stream;
		}

		public extern uint _do_spawn (string path, string[] argv, string[] envp) throws Error;
		public extern void _resume_instance (void * instance);
		public extern void _free_instance (void * instance);
	}
}
#endif
