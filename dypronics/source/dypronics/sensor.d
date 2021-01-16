module dypronics.sensor;

// import hunt.entity;

/// Unique ID of sensor type
alias SensorId = ubyte;

/// Physical value sensor description
struct Sensor {
  SensorId id; /// Database id
  string name; /// Human readable name
  string units; /// Units name
  string color; /// Color in CSS format
}

/// All known sensors
Sensor[6] sensors = [
  Sensor(0, "Temperature sensor", "C", "#cc2020"),
  Sensor(1, "Humid sensor", "%", "#164fcc"),
  Sensor(2, "CO2 sensor", "ppm", "#db7c00"),
  Sensor(3, "PH sensor", "unit", "#00b20b"),
  Sensor(4, "Salinity sensor", "ppt", "#00b1dd"),
  Sensor(5, "Light level sensor", "lux", "#fff200"),
];

/// Sensor data row stored in database
struct SensorData {
  SensorId sensor;
  long time;
  float value;
}
