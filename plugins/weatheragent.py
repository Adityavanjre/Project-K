
class WeatherPlugin:
    def run(self, location="Mumbai"):
        return f"WEATHER REPORT: Simulated 27°C in {location}. Perfect for laboratory operations."

def initialize():
    return WeatherPlugin()
