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
	sensorsData.drop();

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("public/"));
	auto restServer = new RestServer(sensorsData);
	router.registerRestInterface(restServer);
	router.registerWebInterface(new WebInterface(restServer));

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
  void postSensor(SensorId sid, double value);
	Json getSensor(SensorId sid);
}

struct PlotData {
	long[] time; // milli seconds
	double[] values;
}

class RestServer : APIRoot {
	private MongoCollection dataCollection;

	this(MongoCollection coll) {
		dataCollection = coll;
	}

	void postSensor(SensorId sid, double value) {
		auto time = Clock.currTime.toUnixTime;
		dataCollection.insert(SensorData(sid, time, value));
	}

	PlotData sensorDataRaw(SensorId sid) {
		Array!long time;
		Array!double values;
		foreach(doc; dataCollection.find(["sensor": sid])) {
			if(!doc.isNull) {
				time.insertBack(1000 * doc["time"].get!long);
				values.insertBack(doc["value"].to!double);
			}
		}
		return PlotData(time[].array, values[].array);
	}

	Json getSensor(SensorId sid) {
	  return sensorDataRaw(sid).serializeToJson();
	}
}

class WebInterface {
	private {
		// stored in the session store
		SessionVar!(bool, "authenticated") ms_authenticated;
		// Sensor data collection
		RestServer restServer;
	}

	this(RestServer restServer) {
		this.restServer = restServer;
	}

	// GET /
	void index()
	{
		bool authenticated = ms_authenticated;
		PlotData[SensorId] data;
		if(authenticated) {
			foreach(s; sensors) data[s.id] = restServer.sensorDataRaw(s.id);
		}
		render!("index.dt", authenticated, sensors, data);
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
		foreach(s; sensors) {
			client.postSensor(s.id, s.randomValue);
		}
		sleep(1.seconds);
	}
}
