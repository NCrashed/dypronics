import vibe.core.core : runApplication;
import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;
import vibe.web.web;
import vibe.db.mongo.mongo;
import std.datetime.systime;
import dypronics.sensor;

version(unittest) { void main() {}}
else {
void main()
{
	MongoClient client = connectMongoDB("127.0.0.1");
	auto sensorsData = client.getCollection("dypronics.sensors.data");

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("public/"));
	router.registerWebInterface(new WebInterface(sensorsData));

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
		// Sensor data collection
		MongoCollection dataCollection;
	}

	this(MongoCollection coll) {
		dataCollection = coll;
	}

	// GET /
	void index()
	{
		bool authenticated = ms_authenticated;
		render!("index.dt", authenticated, sensors);
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

	void postData(SensorId sid, float value) {
		auto time = Clock.currTime.stdTime;
		dataCollection.insert(SensorData(sid, time, value));
	}
}
