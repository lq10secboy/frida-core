namespace Frida {
	public class PipeTransport : Object {
		public string local_address {
			get;
			construct;
		}

		public string remote_address {
			get;
			construct;
		}

		public void * _backend;

		public PipeTransport () throws IOError {
			string local_address, remote_address;
			var backend = _create_backend (out local_address, out remote_address);
			Object (local_address: local_address, remote_address: remote_address);
			_backend = backend;
		}

		~PipeTransport () {
			_destroy_backend (_backend);
		}

		public static extern void set_temp_directory (string path);

		public static extern void * _create_backend (out string local_address, out string remote_address) throws IOError;
		public static extern void _destroy_backend (void * backend);
	}

	public class Pipe : IOStream {
		public string address {
			get;
			construct;
		}

		public MainContext main_context {
			get;
			construct;
		}

		public override InputStream input_stream {
			get {
				return input;
			}
		}

		public override OutputStream output_stream {
			get {
				return output;
			}
		}

		public void * _backend;

		private PipeInputStream input;
		private PipeOutputStream output;

		public Pipe (string address) throws IOError {
			var backend = _create_backend (address);
			Object (address: address, main_context: MainContext.get_thread_default ());
			_backend = backend;

			input = new PipeInputStream (_backend);
			output = new PipeOutputStream (_backend);
		}

		~Pipe () {
			_destroy_backend (_backend);
		}

		public override bool close (Cancellable? cancellable = null) throws IOError {
			return _close ();
		}

		public static extern void * _create_backend (string address) throws IOError;
		public static extern void _destroy_backend (void * backend);
		public extern bool _close () throws IOError;
	}

	public class PipeInputStream : InputStream {
		public void * _backend;

		public PipeInputStream (void * backend) {
			this._backend = backend;
		}

		public override bool close (GLib.Cancellable? cancellable = null) throws IOError {
			return true;
		}

		public override extern ssize_t read (uint8[] buffer, Cancellable? cancellable = null) throws IOError;
	}

	public class PipeOutputStream : OutputStream {
		public void * _backend;

		public PipeOutputStream (void * backend) {
			this._backend = backend;
		}

		public override bool close (GLib.Cancellable? cancellable = null) throws IOError {
			return true;
		}

		public override extern ssize_t write (uint8[] buffer, Cancellable? cancellable = null) throws IOError;
	}
}
