from fastapi import FastAPI
from schemas import EnvironmentResponse, RouteSuggestionResponse
from services import get_environment_data, get_route_suggestion

app = FastAPI()


@app.get("/")
def home():
    return {"message": "Backend çalışıyor"}


@app.get("/environment", response_model=EnvironmentResponse)
def get_environment(neighborhood: str = "Çünür"):
    return get_environment_data(neighborhood)


@app.get("/route-suggestion", response_model=RouteSuggestionResponse)
def route_suggestion(target: str, mode: str = "walk"):
    return get_route_suggestion(target, mode)