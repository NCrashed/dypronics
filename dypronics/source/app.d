import core.time;
import dypronics.sensor;
import std.array;
import std.container.array;
import std.conv;
import std.datetime.systime;
import std.process;
import std.stdio;
import vibe.core.core;
import vibe.core.path;
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
	// sensorsData.drop();

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
	Json getSensor(SensorId sid, SensorInterval interval, long count);
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

	PlotData sensorDataRaw(SensorId sid, SensorInterval interval, long count) {
		Array!long time;
		Array!double values;
		const now = Clock.currTime.toUnixTime;
		const start = now - (now % interval.asSeconds) - interval.asSeconds * count;
		long tempTime = start;
		double tempValue = 0.0;
		long tempN = 0;
		foreach(doc; dataCollection.find(["sensor": sid.serializeToBson, "time" : [ "$gte": start ].serializeToBson])) {
			if(!doc.isNull) {
				auto t = doc["time"].get!long;
				auto v = doc["value"].to!double;
				if(t >= tempTime + interval.asSeconds) {
					if(tempN > 0) {
						time.insertBack(1000 * tempTime);
						values.insertBack(tempValue / cast(double)tempN);
					}
					tempTime = t;
					tempN = 0;
					tempValue = 0.0;
				}
				tempN += 1;
				tempValue += v;
			}
		}
		if(tempN > 0) {
			time.insertBack(1000 * tempTime);
			values.insertBack(tempValue / cast(double)tempN);
		}
		return PlotData(time[].array, values[].array);
	}

	Json getSensor(SensorId sid, SensorInterval interval, long count) {
	  return sensorDataRaw(sid, interval, count).serializeToJson();
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
			foreach(s; sensors) data[s.id] = restServer.sensorDataRaw(s.id, SensorInterval.minute, 10);
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

	// Get archive of raw data
	@method(HTTPMethod.GET) @path("archive")
	void getArchive(HTTPServerRequest req, HTTPServerResponse res, SensorInterval interval, long count) {
		bool authenticated = ms_authenticated;
		enforceHTTP(authenticated, HTTPStatus.forbidden, "Not logged in.");

		auto mkdirRes = executeShell("mkdir -p /tmp/dypronics");
		enforceHTTP(mkdirRes.status == 0, HTTPStatus.internalServerError,
			"Failed to make temporary dir: " ~ mkdirRes.output);
		foreach(s; sensors) {
			auto data = restServer.sensorDataRaw(s.id, interval, count);
			auto f = File("/tmp/dypronics/" ~ s.nameShort ~ ".csv", "w");
			f.writeln("Time,Value");
			for(size_t i = 0; i < data.time.length; i++) {
				f.writeln(data.time[i],",",data.values[i]);
			}
		}
		executeShell("rm /tmp/dypronics.zip");
		auto zipRes = executeShell("cd /tmp && zip -r dypronics.zip dypronics");
		enforceHTTP(zipRes.status == 0, HTTPStatus.internalServerError,
			"Failed to zip archive: " ~ zipRes.output);
		scope(exit) {
			executeShell("rm -rf /tmp/dypronics");
		}
		sendFile(req, res, NativePath("/tmp/dypronics.zip"));
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
