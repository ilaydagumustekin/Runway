def calculate_myki_score(overall_score: int) -> int:
    return overall_score


def get_environment_data(neighborhood: str = "Çünür") -> dict:
    environment_data = {
        "Çünür": {
            "city": "Isparta",
            "overall_score": 82,
            "overall_status": "İyi",
            "last_update_text": "Son güncelleme: 2 dk önce",
            "air_quality": 42,
            "noise_level": 63,
            "green_ratio": 18,
            "weather_temp_text": "18°C",
            "weather_desc": "Parçalı Bulutlu",
        },
        "Bahçelievler": {
            "city": "Isparta",
            "overall_score": 74,
            "overall_status": "Orta",
            "last_update_text": "Son güncelleme: 5 dk önce",
            "air_quality": 50,
            "noise_level": 58,
            "green_ratio": 22,
            "weather_temp_text": "17°C",
            "weather_desc": "Açık",
        },
        "Isparta Merkez": {
            "city": "Isparta",
            "overall_score": 68,
            "overall_status": "Orta",
            "last_update_text": "Son güncelleme: 3 dk önce",
            "air_quality": 57,
            "noise_level": 66,
            "green_ratio": 15,
            "weather_temp_text": "16°C",
            "weather_desc": "Hafif Yağmurlu",
        },
    }
    selected_neighborhood = neighborhood if neighborhood in environment_data else "Çünür"
    selected_data = environment_data[selected_neighborhood]

    myki_score = calculate_myki_score(selected_data["overall_score"])

    return {
        "neighborhood": selected_neighborhood,
        "city": selected_data["city"],
        "overall_score": selected_data["overall_score"],
        "overall_status": selected_data["overall_status"],
        "last_update_text": selected_data["last_update_text"],
        "air_quality": selected_data["air_quality"],
        "noise_level": selected_data["noise_level"],
        "green_ratio": selected_data["green_ratio"],
        "weather_temp_text": selected_data["weather_temp_text"],
        "weather_desc": selected_data["weather_desc"],
        "myki_score": myki_score,
    }


def get_route_suggestion(target: str, mode: str = "walk") -> dict:
    route_data = {
        "Merkez": {
            "distance_km": 1.2,
            "route_score": 78,
            "warning_text": "Uyarı: Gürültülü alan olabilir",
            "walk_eta": 12,
        },
        "Otogar": {
            "distance_km": 3.4,
            "route_score": 70,
            "warning_text": "Uyarı: Trafik yoğun olabilir",
            "walk_eta": 30,
        },
        "Üniversite": {
            "distance_km": 2.1,
            "route_score": 84,
            "warning_text": "Uyarı: Yol çalışması olabilir",
            "walk_eta": 21,
        },
    }
    selected_target = target if target in route_data else "Merkez"
    selected_mode = mode if mode in {"walk", "bike", "scooter"} else "walk"
    selected_data = route_data[selected_target]

    walk_eta = selected_data["walk_eta"]
    mode_eta = {
        "walk": walk_eta,
        "bike": max(1, round(walk_eta * 0.45)),
        "scooter": max(1, round(walk_eta * 0.6)),
    }

    return {
        "target": selected_target,
        "travel_mode": selected_mode,
        "eta_minutes": mode_eta[selected_mode],
        "distance_km": selected_data["distance_km"],
        "route_score": selected_data["route_score"],
        "warning_text": selected_data["warning_text"],
    }
