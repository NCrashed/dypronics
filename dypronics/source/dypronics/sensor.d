module dypronics.sensor;

import std.random;

/// Unique ID of sensor type
alias SensorId = ubyte;

/// Physical value sensor description
struct Sensor {
  SensorId id; /// Database id
  string nameShort; /// Short name for files
  string name; /// Human readable name
  string units; /// Units name
  string color; /// Color in CSS format
  double minValue;
  double maxValue;

  double randomValue() {
    return uniform!"[]"(minValue, maxValue);
  }
}

/// All known sensors
Sensor[6] sensors = [
  Sensor(0, "temperature", "Temperature sensor", "C", "#cc2020", -60, 60),
  Sensor(1, "humid", "Humid sensor", "%", "#164fcc", 0, 100),
  Sensor(2, "co2", "CO2 sensor", "ppm", "#db7c00", 0, 1000),
  Sensor(3, "ph", "PH sensor", "unit", "#00b20b", 0, 12),
  Sensor(4, "salinity", "Salinity sensor", "ppt", "#00b1dd", 0, 1000),
  Sensor(5, "light", "Light level sensor", "lux", "#fff200", 0, 1000),
];

/// Sensor data row stored in database
struct SensorData {
  SensorId sensor;
  long time; // seconds
  double value;
}

/// Time unit of sensor data
enum SensorInterval {
  second,
  minute,
  hour,
  day,
}

long asSeconds(SensorInterval i) {
  final switch(i) {
    case SensorInterval.second: return 1;
    case SensorInterval.minute: return 60;
    case SensorInterval.hour: return 3600;
    case SensorInterval.day: return 24*3600;
  }
}
