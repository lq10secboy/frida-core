namespace Frida.HostSessionTest {
	public static void add_tests () {
		GLib.Test.add_func ("/HostSession/Service/provider-available", () => {
			var h = new Harness ((h) => Service.provider_available.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Service/provider-unavailable", () => {
			var h = new Harness ((h) => Service.provider_unavailable.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Manual/full-cycle", () => {
			var h = new Harness.without_timeout ((h) => Service.Manual.full_cycle.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Manual/error-feedback", () => {
			var h = new Harness.without_timeout ((h) => Service.Manual.error_feedback.begin (h as Harness));
			h.run ();
		});

#if !LINUX
		GLib.Test.add_func ("/HostSession/Fruity/PropertyList/can-construct-from-xml-document", () => {
			Fruity.PropertyList.can_construct_from_xml_document ();
		});

		GLib.Test.add_func ("/HostSession/Fruity/PropertyList/to-xml-yields-complete-document", () => {
			Fruity.PropertyList.to_xml_yields_complete_document ();
		});

		GLib.Test.add_func ("/HostSession/Fruity/backend", () => {
			var h = new Harness ((h) => Fruity.backend.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Fruity/large-messages", () => {
			var h = new Harness ((h) => Fruity.large_messages.begin (h as Harness));
			h.run ();
		});
#endif

#if LINUX
		GLib.Test.add_func ("/HostSession/Linux/spawn", () => {
			var h = new Harness ((h) => Linux.spawn.begin (h as Harness));
			h.run ();
		});
#endif

#if DARWIN
		GLib.Test.add_func ("/HostSession/Darwin/backend", () => {
			var h = new Harness ((h) => Darwin.backend.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Darwin/spawn", () => {
			var h = new Harness ((h) => Darwin.spawn.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Darwin/Manual/cross-arch", () => {
			var h = new Harness ((h) => Darwin.Manual.cross_arch.begin (h as Harness));
			h.run ();
		});
#endif

#if WINDOWS
		GLib.Test.add_func ("/HostSession/Windows/backend", () => {
			var h = new Harness ((h) => Windows.backend.begin (h as Harness));
			h.run ();
		});

		GLib.Test.add_func ("/HostSession/Windows/spawn", () => {
			var h = new Harness ((h) => Windows.spawn.begin (h as Harness));
			h.run ();
		});
#endif

	}

	namespace Service {

		private static async void provider_available (Harness h) {
			h.assert_no_providers_available ();
			var backend = new StubBackend ();
			h.service.add_backend (backend);
			yield h.process_events ();
			h.assert_no_providers_available ();

			yield h.service.start ();
			h.assert_no_providers_available ();
			yield h.process_events ();
			h.assert_n_providers_available (1);

			yield h.service.stop ();
			h.service.remove_backend (backend);

			h.done ();
		}

		private static async void provider_unavailable (Harness h) {
			var backend = new StubBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);

			backend.disable_provider ();
			h.assert_n_providers_available (0);

			yield h.service.stop ();
			h.service.remove_backend (backend);

			h.done ();
		}

		private class StubBackend : Object, HostSessionBackend {
			private StubProvider provider = new StubProvider ();

			public async void start () {
				var source = new IdleSource ();
				source.set_callback (() => {
					provider_available (provider);
					return false;
				});
				source.attach (MainContext.get_thread_default ());
			}

			public async void stop () {
			}

			public void disable_provider () {
				provider_unavailable (provider);
			}
		}

		private class StubProvider : Object, HostSessionProvider {
			public string name {
				get { return "Stub"; }
			}

			public ImageData? icon {
				get { return _icon; }
			}
			private ImageData? _icon;

			public HostSessionProviderKind kind {
				get { return HostSessionProviderKind.LOCAL_SYSTEM; }
			}

			public async HostSession create (string? location = null) throws Error {
				throw new Error.NOT_SUPPORTED ("Not implemented");
			}

			public async void destroy (HostSession session) throws Error {
				throw new Error.NOT_SUPPORTED ("Not implemented");
			}

			public async AgentSession obtain_agent_session (HostSession host_session, AgentSessionId agent_session_id) throws Error {
				throw new Error.NOT_SUPPORTED ("Not implemented");
			}
		}

		namespace Manual {

			private static async void full_cycle (Harness h) {
				if (!GLib.Test.slow ()) {
					stdout.printf ("<skipping, run in slow mode with target application running> ");
					h.done ();
					return;
				}

				try {
					var device_manager = new DeviceManager ();

					var devices = yield device_manager.enumerate_devices ();
					Device device = null;
					var num_devices = devices.size ();
					for (var i = 0; i != num_devices && device == null; i++) {
						var d = devices.get (i);
						if (d.dtype == DeviceType.LOCAL)
							device = d;
					}
					assert (device != null);

					stdout.printf ("\n\nUsing \"%s\"\n", device.name);
					stdout.printf ("Enter PID: ");
					stdout.flush ();
					uint pid = (uint) int.parse (stdin.read_line ());

					stdout.printf ("Attaching...\n");
					var session = yield device.attach (pid);
					stdout.printf ("Attached!\n");

					stdout.printf ("Enabling debugger...\n");
					yield session.enable_debugger (5858);
					stdout.printf ("Debugger listening on port 5858\n");

					while (true)
						yield h.process_events ();
				} catch (Error e) {
					printerr ("\nFAIL: %s\n\n", e.message);
					assert_not_reached ();
				}
			}

			private static async void error_feedback (Harness h) {
				if (!GLib.Test.slow ()) {
					stdout.printf ("<skipping, run in slow mode> ");
					h.done ();
					return;
				}

				try {
					var device_manager = new DeviceManager ();

					var devices = yield device_manager.enumerate_devices ();
					Device device = null;
					var num_devices = devices.size ();
					for (var i = 0; i != num_devices && device == null; i++) {
						var d = devices.get (i);
						if (d.dtype == DeviceType.LOCAL)
							device = d;
					}
					assert (device != null);

					stdout.printf ("\n\nEnter an absolute path that does not exist: ");
					stdout.flush ();
					var inexistent_path = stdin.read_line ();
					try {
						stdout.printf ("Trying to spawn program at inexistent path '%s'...", inexistent_path);
						yield device.spawn (inexistent_path, new string[] { inexistent_path }, new string[] {});
						assert_not_reached ();
					} catch (Error e) {
						stdout.printf ("\nResult: \"%s\"\n", e.message);
						assert (e is Error.EXECUTABLE_NOT_FOUND);
						assert (e.message == "Unable to find executable at '%s'".printf (inexistent_path));
					}

					stdout.printf ("\nEnter an absolute path that exists but is not a valid executable: ");
					stdout.flush ();
					var nonexec_path = stdin.read_line ();
					try {
						stdout.printf ("Trying to spawn program at non-executable path '%s'...", nonexec_path);
						yield device.spawn (nonexec_path, new string[] { nonexec_path }, new string[] {});
						assert_not_reached ();
					} catch (Error e) {
						stdout.printf ("\nResult: \"%s\"\n", e.message);
						assert (e is Error.EXECUTABLE_NOT_SUPPORTED);
						assert (e.message == "Unable to spawn executable at '%s': unsupported file format".printf (nonexec_path));
					}

					var processes = yield device.enumerate_processes ();
					uint inexistent_pid = 100000;
					bool exists = false;
					do {
						exists = false;
						var num_processes = processes.size ();
						for (var i = 0; i != num_processes && !exists; i++) {
							var process = processes.get (i);
							if (process.pid == inexistent_pid) {
								exists = true;
								inexistent_pid++;
							}
						}
					} while (exists);

					try {
						stdout.printf ("\nTrying to attach to inexistent pid %u...", inexistent_pid);
						stdout.flush ();
						yield device.attach (inexistent_pid);
						assert_not_reached ();
					} catch (Error e) {
						stdout.printf ("\nResult: \"%s\"\n", e.message);
						assert (e is Error.PROCESS_NOT_FOUND);
						assert (e.message == "Unable to find process with pid %u".printf (inexistent_pid));
					}

					stdout.printf ("\nEnter PID of a process that you don't have access to: ");
					stdout.flush ();
					uint privileged_pid = (uint) int.parse (stdin.read_line ());

					try {
						stdout.printf ("Trying to attach to %u...", privileged_pid);
						stdout.flush ();
						yield device.attach (privileged_pid);
						assert_not_reached ();
					} catch (Error e) {
						stdout.printf ("\nResult: \"%s\"\n\n", e.message);
						assert (e is Error.PERMISSION_DENIED);
						assert (e.message == "Unable to access process with pid %u from the current user account".printf (privileged_pid));
					}

					yield device_manager.close ();

					h.done ();
				} catch (Error e) {
					printerr ("\nFAIL: %s\n\n", e.message);
					assert_not_reached ();
				}
			}

		}

	}

#if LINUX
	namespace Linux {

		private static async void spawn (Harness h) {
			var backend = new LinuxHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);
			var prov = h.first_provider ();

			try {
				var host_session = yield prov.create ();

				var tests_dir = Path.get_dirname (Frida.Test.Process.current.filename);
				var victim_path = Path.build_filename (tests_dir, "data", "unixvictim" + Frida.Test.arch_suffix ());
				string[] argv = { victim_path };
				string[] envp = {};
				var pid = yield host_session.spawn (victim_path, argv, envp);
				var session_id = yield host_session.attach_to (pid);
				var session = yield prov.obtain_agent_session (host_session, session_id);
				string received_message = null;
				var message_handler = session.message_from_script.connect ((script_id, message, data) => {
					received_message = message;
					spawn.callback ();
				});
				var script_id = yield session.create_script ("spawn",
					"Process.enumerateModules({" +
					"  onMatch: function (m) {" +
					"    if (m.name.indexOf('libc') === 0) {" +
					"      Interceptor.attach (Module.findExportByName(m.name, 'sleep'), {" +
					"        onEnter: function (args) {" +
					"          send({ seconds: args[0].toInt32() });" +
					"        }" +
					"      });" +
					"    }" +
					"  }," +
					"  onComplete: function () {}" +
					"});");
				yield session.load_script (script_id);
				yield host_session.resume (pid);
				yield;
				session.disconnect (message_handler);
				assert (received_message == "{\"type\":\"send\",\"payload\":{\"seconds\":60}}");
				yield host_session.kill (pid);
			} catch (GLib.Error e) {
				stderr.printf ("Unexpected error: %s\n", e.message);
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);
			h.done ();
		}

	}
#endif

#if DARWIN
	namespace Darwin {

		private static async void backend (Harness h) {
			var backend = new DarwinHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);
			var prov = h.first_provider ();

			assert (prov.name == "Local System");

			if (Frida.Test.os () == Frida.Test.OS.MAC) {
				var icon = prov.icon;
				assert (icon != null);
				assert (icon.width == 16 && icon.height == 16);
				assert (icon.rowstride == icon.width * 4);
				assert (icon.pixels.length > 0);
			}

			try {
				var session = yield prov.create ();
				var processes = yield session.enumerate_processes ();
				assert (processes.length > 0);

				if (GLib.Test.verbose ()) {
					foreach (var process in processes)
						stdout.printf ("pid=%u name='%s'\n", process.pid, process.name);
				}
			} catch (GLib.Error e) {
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);
			h.done ();
		}

		private static async void spawn (Harness h) {
			if (Frida.Test.os () != Frida.Test.OS.MAC || sizeof (size_t) != 8) {
				stdout.printf ("<skipping, only available on 64-bit Mac for now> ");
				h.done ();
				return;
			}

			var backend = new DarwinHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);
			var prov = h.first_provider ();

			try {
				var host_session = yield prov.create ();

				var tests_dir = Path.get_dirname (Frida.Test.Process.current.filename);
				var victim_path = Path.build_filename (tests_dir, "data", "unixvictim-mac");
				string[] argv = { victim_path };
				string[] envp = {};
				var pid = yield host_session.spawn (victim_path, argv, envp);
				var session_id = yield host_session.attach_to (pid);
				var session = yield prov.obtain_agent_session (host_session, session_id);
				string received_message = null;
				var message_handler = session.message_from_script.connect ((script_id, message, data) => {
					received_message = message;
					spawn.callback ();
				});
				var script_id = yield session.create_script ("spawn",
					"Interceptor.attach (Module.findExportByName('libSystem.B.dylib', 'sleep'), {" +
					"  onEnter: function (args) {" +
					"    send({ seconds: args[0].toInt32() });" +
					"  }" +
					"});");
				yield session.load_script (script_id);
				yield host_session.resume (pid);
				yield;
				session.disconnect (message_handler);
				assert (received_message == "{\"type\":\"send\",\"payload\":{\"seconds\":60}}");
				yield host_session.kill (pid);
			} catch (GLib.Error e) {
				stderr.printf ("Unexpected error: %s\n", e.message);
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);
			h.done ();
		}

		namespace Manual {

			private static async void cross_arch (Harness h) {
				if (!GLib.Test.slow ()) {
					stdout.printf ("<skipping, run in slow mode with target application running> ");
					h.done ();
					return;
				}

				uint pid;

				try {
					string pgrep_output;
					GLib.Process.spawn_sync (null, new string[] { "/usr/bin/pgrep", "Safari" }, null, 0, null, out pgrep_output, null, null);
					pid = (uint) int.parse (pgrep_output);
				} catch (SpawnError spawn_error) {
					stderr.printf ("ERROR: %s\n", spawn_error.message);
					assert_not_reached ();
				}

				var backend = new DarwinHostSessionBackend ();
				h.service.add_backend (backend);
				yield h.service.start ();
				yield h.process_events ();
				var prov = h.first_provider ();

				try {
					var host_session = yield prov.create ();
					var id = yield host_session.attach_to (pid);
					yield prov.obtain_agent_session (host_session, id);
				} catch (GLib.Error e) {
					stderr.printf ("ERROR: %s\n", e.message);
					assert_not_reached ();
				}

				yield h.service.stop ();
				h.service.remove_backend (backend);

				h.done ();
			}

		}

	}
#endif

#if WINDOWS
	namespace Windows {

		private static async void backend (Harness h) {
			var backend = new WindowsHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);
			var prov = h.first_provider ();

			assert (prov.name == "Local System");

			var icon = prov.icon;
			assert (icon != null);
			assert (icon.width == 16 && icon.height == 16);
			assert (icon.rowstride == icon.width * 4);
			assert (icon.pixels.length > 0);

			try {
				var session = yield prov.create ();
				var processes = yield session.enumerate_processes ();
				assert (processes.length > 0);

				if (GLib.Test.verbose ()) {
					foreach (var process in processes)
						stdout.printf ("pid=%u name='%s'\n", process.pid, process.name);
				}
			} catch (GLib.Error e) {
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);

			h.done ();
		}

		private static async void spawn (Harness h) {
			var backend = new WindowsHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			yield h.process_events ();
			h.assert_n_providers_available (1);
			var prov = h.first_provider ();

			try {
				var host_session = yield prov.create ();

				var self_filename = Frida.Test.Process.current.filename;
				var rat_directory = Path.build_filename (Path.get_dirname (Path.get_dirname (Path.get_dirname (Path.get_dirname (Path.get_dirname (self_filename))))),
					"frida-core", "tests", "labrats");
				var victim_path = Path.build_filename (rat_directory, "winvictim-sleepy%d.exe".printf (sizeof (void *) == 4 ? 32 : 64));
				string[] argv = { victim_path };
				string[] envp = {};
				var pid = yield host_session.spawn (victim_path, argv, envp);
				var session_id = yield host_session.attach_to (pid);
				var session = yield prov.obtain_agent_session (host_session, session_id);
				string received_message = null;
				var message_handler = session.message_from_script.connect ((script_id, message, data) => {
					received_message = message;
					spawn.callback ();
				});
				var script_id = yield session.create_script ("spawn",
					"Interceptor.attach (Module.findExportByName('user32.dll', 'GetMessageW'), {" +
					"  onEnter: function (args) {" +
					"    send('GetMessage');" +
					"  }" +
					"});");
				yield session.load_script (script_id);
				yield host_session.resume (pid);
				yield;
				session.disconnect (message_handler);
				assert (received_message == "{\"type\":\"send\",\"payload\":\"GetMessage\"}");
				yield host_session.kill (pid);
			} catch (GLib.Error e) {
				stderr.printf ("Unexpected error: %s\n", e.message);
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);
			h.done ();
		}

	}
#endif

#if !LINUX
	namespace Fruity {

		private static async void backend (Harness h) {
			if (!GLib.Test.slow ()) {
				stdout.printf ("<skipping, run in slow mode with iOS device connected> ");
				h.done ();
				return;
			}

			var backend = new FruityHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			h.disable_timeout (); /* this is a manual test after all */
			yield h.wait_for_provider ();
			var prov = h.first_provider ();

#if WINDOWS
			assert (prov.name != "Apple Mobile Device"); /* should manage to extract a user-defined name */
#endif

			var icon = prov.icon;
			assert (icon != null);
			assert (icon.width == 16 && icon.height == 16);
			assert (icon.rowstride == icon.width * 4);
			assert (icon.pixels.length > 0);

			try {
				var session = yield prov.create ();
				var processes = yield session.enumerate_processes ();
				assert (processes.length > 0);

				if (GLib.Test.verbose ()) {
					foreach (var process in processes)
						stdout.printf ("pid=%u name='%s'\n", process.pid, process.name);
				}
			} catch (GLib.Error e) {
				printerr ("\nFAIL: %s\n\n", e.message);
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);

			h.done ();
		}

		private static async void large_messages (Harness h) {
			if (!GLib.Test.slow ()) {
				stdout.printf ("<skipping, run in slow mode with iOS device connected> ");
				h.done ();
				return;
			}

			var backend = new FruityHostSessionBackend ();
			h.service.add_backend (backend);
			yield h.service.start ();
			h.disable_timeout (); /* this is a manual test after all */
			yield h.wait_for_provider ();
			var prov = h.first_provider ();

			try {
				stdout.printf ("connecting to frida-server\n");
				var host_session = yield prov.create ();
				stdout.printf ("enumerating processes\n");
				var processes = yield host_session.enumerate_processes ();
				assert (processes.length > 0);

				HostProcessInfo? process = null;
				foreach (var p in processes) {
					if (p.name == "hello-frida") {
						process = p;
						break;
					}
				}
				assert (process != null);

				stdout.printf ("attaching to target process\n");
				var session_id = yield host_session.attach_to (process.pid);
				var session = yield prov.obtain_agent_session (host_session, session_id);
				string received_message = null;
				var message_handler = session.message_from_script.connect ((script_id, message, data) => {
					received_message = message;
					large_messages.callback ();
				});
				stdout.printf ("creating script\n");
				var script_id = yield session.create_script ("large-messages",
					"function onMessage(message) {" +
					"  send(\"ACK: \" + message.length);" +
					"  recv(onMessage);" +
					"}" +
					"recv(onMessage);"
				);
				stdout.printf ("loading script\n");
				yield session.load_script (script_id);
				var steps = new uint[] { 1024, 4096, 8192, 16384, 32768 };
				var transport_overhead = 163;
				foreach (var step in steps) {
					var builder = new StringBuilder ();
					builder.append ("\"");
					for (var i = 0; i != step - transport_overhead; i++) {
						builder.append ("s");
					}
					builder.append ("\"");
					yield session.post_message_to_script (script_id, builder.str);
					yield;
					stdout.printf ("received message: '%s'\n", received_message);
				}
				session.disconnect (message_handler);

				yield session.destroy_script (script_id);
				yield session.close ();
			} catch (GLib.Error e) {
				printerr ("\nFAIL: %s\n\n", e.message);
				assert_not_reached ();
			}

			yield h.service.stop ();
			h.service.remove_backend (backend);

			h.done ();
		}

		namespace PropertyList {

			private static void can_construct_from_xml_document () {
				var xml =
					"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
					"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
					"<plist version=\"1.0\">\n" +
					"<dict>\n" +
					"	<key>DeviceID</key>\n" +
					"	<integer>2</integer>\n" +
					"	<key>MessageType</key>\n" +
					"	<string>Attached</string>\n" +
					"	<key>Properties</key>\n" +
					"	<dict>\n" +
					"		<key>ConnectionType</key>\n" +
					"		<string>USB</string>\n" +
					"		<key>DeviceID</key>\n" +
					"		<integer>2</integer>\n" +
					"		<key>LocationID</key>\n" +
					"		<integer>0</integer>\n" +
					"		<key>ProductID</key>\n" +
					"		<integer>4759</integer>\n" +
					"		<key>SerialNumber</key>\n" +
					"		<string>220f889780dda462091a65df48b9b6aedb05490f</string>\n" +
					"	</dict>\n" +
					"</dict>\n" +
					"</plist>\n";
				try {
					var plist = new Frida.Fruity.PropertyList.from_xml (xml);
					var plist_keys = plist.get_keys ();
					assert (plist_keys.length == 3);
					assert (plist.get_int ("DeviceID") == 2);
					assert (plist.get_string ("MessageType") == "Attached");

					var proplist = plist.get_plist ("Properties");
					var proplist_keys = proplist.get_keys ();
					assert (proplist_keys.length == 5);
					assert (proplist.get_string ("ConnectionType") == "USB");
					assert (proplist.get_int ("DeviceID") == 2);
					assert (proplist.get_int ("LocationID") == 0);
					assert (proplist.get_int ("ProductID") == 4759);
					assert (proplist.get_string ("SerialNumber") == "220f889780dda462091a65df48b9b6aedb05490f");
				} catch (IOError e) {
					assert_not_reached ();
				}
			}

			private static void to_xml_yields_complete_document () {
				var plist = new Frida.Fruity.PropertyList ();
				plist.set_string ("MessageType", "Detached");
				plist.set_int ("DeviceID", 2);

				var proplist = new Frida.Fruity.PropertyList ();
				proplist.set_string ("ConnectionType", "USB");
				proplist.set_int ("DeviceID", 2);
				plist.set_plist ("Properties", proplist);

				var actual_xml = plist.to_xml ();
				var expected_xml =
					"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
					"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
					"<plist version=\"1.0\">\n" +
					"<dict>\n" +
					"	<key>DeviceID</key>\n" +
					"	<integer>2</integer>\n" +
					"	<key>MessageType</key>\n" +
					"	<string>Detached</string>\n" +
					"	<key>Properties</key>\n" +
					"	<dict>\n" +
					"		<key>ConnectionType</key>\n" +
					"		<string>USB</string>\n" +
					"		<key>DeviceID</key>\n" +
					"		<integer>2</integer>\n" +
					"	</dict>\n" +
					"</dict>\n" +
					"</plist>\n";
				assert (actual_xml == expected_xml);
			}

		}

	}
#endif

	public class Harness : Frida.Test.AsyncHarness {
		public HostSessionService service {
			get;
			private set;
		}

		private uint timeout = 20;

		private Gee.ArrayList<HostSessionProvider> available_providers = new Gee.ArrayList<HostSessionProvider> ();

		public Harness (owned Frida.Test.AsyncHarness.TestSequenceFunc func) {
			base ((owned) func);
		}

		public Harness.without_timeout (owned Frida.Test.AsyncHarness.TestSequenceFunc func) {
			base ((owned) func);
			timeout = 0;
		}

		construct {
			service = new HostSessionService ();
			service.provider_available.connect ((provider) => {
				assert (available_providers.add (provider));
			});
			service.provider_unavailable.connect ((provider) => {
				assert (available_providers.remove (provider));
			});
		}

		protected override uint provide_timeout () {
			return timeout;
		}

		public async void wait_for_provider () {
			while (available_providers.is_empty) {
				yield process_events ();
			}
		}

		public void assert_no_providers_available () {
			assert (available_providers.is_empty);
		}

		public void assert_n_providers_available (int n) {
			assert (available_providers.size == n);
		}

		public HostSessionProvider first_provider () {
			assert (available_providers.size >= 1);
			return available_providers[0];
		}
	}
}
