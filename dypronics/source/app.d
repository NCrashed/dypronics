import vibe.core.core : runApplication;
import vibe.http.router;
import vibe.http.server;
import vibe.web.web;

version(unittest) { void main() {}}
else {
void main()
{
	auto router = new URLRouter;
	router.registerWebInterface(new WebInterface);

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["0.0.0.0"];
	settings.sessionStore = new MemorySessionStore;

	auto l = listenHTTP(settings, router);
	scope (exit) l.stopListening( );

	runApplication();
}
}

class WebInterface {
	private {
		// stored in the session store
		SessionVar!(bool, "authenticated") ms_authenticated;
	}

	// GET /
	void index()
	{
		bool authenticated = ms_authenticated;
		render!("index.dt", authenticated);
	}

	// POST /login (username and password are automatically read as form fields)
	void postLogin(string username, string password)
	{
		enforceHTTP(username == "user" && password == "secret",
			HTTPStatus.forbidden, "Invalid user name or password.");
		ms_authenticated = true;
		redirect("/");
	}

	// POST /logout
	@method(HTTPMethod.POST) @path("logout")
	void postLogout()
	{
		ms_authenticated = false;
		terminateSession();
		redirect("/");
	}
}
