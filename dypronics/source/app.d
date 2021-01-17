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
import vibe.http.client;
import vibe.web.rest;
import vibe.web.web;
import vibe.web.auth;

version(unittest) { void main() {}}
else {
void main()
{
	MongoClient client = connectMongoDB("127.0.0.1");
	auto sensorsData = client.getCollection("dypronics.sensors.data");
	// sensorsData.drop();

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("public/"));
	router.registerWebInterface(new WebInterface(sensorsData));

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

struct AuthInfo {
	@safe:
	string userName;

	bool isAdmin() { return userName == "admin"; }
	bool isSensor() { return !isAdmin(); }
}

struct PlotData {
	long[] time; // milli seconds
	double[] values;
}

@requiresAuth
class WebInterface {
	private MongoCollection dataCollection;

	this(MongoCollection coll) {
		dataCollection = coll;
	}

	@noRoute
  AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res) @safe
	{
		if (!req.session || !req.session.isKeySet("auth"))
			throw new HTTPStatusException(HTTPStatus.forbidden, "Not authorized to perform this action!");

		return req.session.get!AuthInfo("auth");
  }

	// GET /
	@noAuth
	void index(scope HTTPServerRequest req, scope HTTPServerResponse res)
	{
		bool authenticated = req.session && req.session.isKeySet("auth");
		PlotData[SensorId] data;
		if(authenticated) {
			foreach(s; sensors) data[s.id] = getSensorData(s.id, SensorInterval.minute, 10);
		}
		render!("index.dt", authenticated, sensors, data);
	}

	@noAuth
	void postSensor(SensorId sid, double value) {
		auto time = Clock.currTime.toUnixTime;
		dataCollection.insert(SensorData(sid, time, value));
	}

	@noRoute
	PlotData getSensorData(SensorId sid, SensorInterval interval, long count) {
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

	@auth(Role.admin)
	Json getSensor(SensorId sid, SensorInterval interval, long count) {
	  return getSensorData(sid, interval, count).serializeToJson();
	}

	// POST /login (username and password are automatically read as form fields)
	@noAuth
	void postLogin(scope HTTPServerRequest req, scope HTTPServerResponse res, string username, string password)
	{
		enforceHTTP(username == "admin" && password == "secret",
			HTTPStatus.forbidden, "Invalid user name or password.");
		auto info = AuthInfo(username);

		auto session = !req.session ? res.startSession() : req.session;
		session.set("auth", info);

		redirect("/");
	}

	// POST /logout
	@anyAuth
	void postLogout(scope HTTPServerRequest req, scope HTTPServerResponse res)
	{
		req.session.remove("auth");
		terminateSession();
		redirect("/");
	}

	// Get archive of raw data
	@auth(Role.admin) @method(HTTPMethod.GET) @path("archive")
	void getArchive(HTTPServerRequest req, HTTPServerResponse res, SensorInterval interval, long count) {
		auto mkdirRes = executeShell("mkdir -p /tmp/dypronics");
		enforceHTTP(mkdirRes.status == 0, HTTPStatus.internalServerError,
			"Failed to make temporary dir: " ~ mkdirRes.output);
		foreach(s; sensors) {
			auto data = getSensorData(s.id, interval, count);
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
	// auto client = new RestInterfaceClient!APIRoot("http://127.0.0.1:8080/");

	while(true) {
		foreach(s; sensors) {
			requestHTTP("http://127.0.0.1:8080/sensor",
				(scope req) {
					req.method = HTTPMethod.POST;
					req.writeFormBody(["sid": s.id.to!string, "value": s.randomValue.to!string]);
				},
				(scope res) {

				});
		}
		sleep(1.seconds);
	}
}
