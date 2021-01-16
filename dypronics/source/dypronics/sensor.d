module dypronics.sensor;

/// Unique ID of sensor type
alias SensorId = string;

/// Physical value sensor description
struct Sensor {
  SensorId id; /// Database id
  string name; /// Human readable name
  string units; /// Units name
  string color; /// Color in CSS format
}

/// All known sensors
Sensor[6] sensors = [
  Sensor("temp", "Temperature sensor", "C", "#cc2020"),
  Sensor("humid", "Humid sensor", "%", "#164fcc"),
  Sensor("co2", "CO2 sensor", "ppm", "#db7c00"),
  Sensor("ph", "PH sensor", "unit", "#00b20b"),
  Sensor("salt", "Salinity sensor", "ppt", "#00b1dd"),
  Sensor("light", "Light level sensor", "lux", "#fff200"),
];
