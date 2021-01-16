import dypronics.sensor;
import core.time;
import std.array;
import std.container.array;
import std.conv;
import std.datetime.systime;
import vibe.core.core : runApplication;
import vibe.core.core;
import vibe.db.mongo.mongo;
import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;
import vibe.web.rest;
import vibe.web.web;

version(unittest) { void main() {}}
else {
void main()
{
	MongoClient client = connectMongoDB("127.0.0.1");
	auto sensorsData = client.getCollection("dypronics.sensors.data");

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("public/"));
	router.registerWebInterface(new WebInterface(sensorsData));
	router.registerRestInterface(new RestServer(sensorsData));

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["0.0.0.0"];
	settings.sessionStore = new MemorySessionStore;

	auto l = listenHTTP(settings, router);
	scope (exit) l.stopListening( );

	runTask(&simulateData);

	runApplication();
}
}

@path("/api/")
interface APIRoot {
  void postData(SensorId sid, double value);
	Json getData(SensorId sid);
}

class RestServer : APIRoot {
	private MongoCollection dataCollection;

	this(MongoCollection coll) {
		dataCollection = coll;
	}

	void postData(SensorId sid, double value) {
		auto time = Clock.currTime.toUnixTime;
		dataCollection.insert(SensorData(sid, time, value));
	}

	struct PlotData {
		long[] time; // seconds
		double[] values;
	}
	Json getData(SensorId sid) {
		Array!long time;
		Array!double values;
		foreach(doc; dataCollection.find(["sensor": sid])) {
			time.insertBack(doc["time"].get!long);
			values.insertBack(doc["values"].to!double);
		}
		return PlotData(time[].array, values[].array).serializeToJson();
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
}

void simulateData() {
	auto client = new RestInterfaceClient!APIRoot("http://127.0.0.1:8080/");
	while(true) {
		import std.stdio; writeln("Generate data");
		foreach(s; sensors) {
			client.postData(s.id, s.randomValue);
		}
		sleep(1.seconds);
	}
}
