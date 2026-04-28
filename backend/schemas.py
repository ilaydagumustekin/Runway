from pydantic import BaseModel


class EnvironmentResponse(BaseModel):
    neighborhood: str
    city: str
    overall_score: int
    overall_status: str
    last_update_text: str
    air_quality: int
    noise_level: int
    green_ratio: int
    weather_temp_text: str
    weather_desc: str
    myki_score: int


class RouteSuggestionResponse(BaseModel):
    target: str
    travel_mode: str
    eta_minutes: int
    distance_km: float
    route_score: int
    warning_text: str
