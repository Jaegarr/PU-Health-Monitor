import fastf1, os
import pandas as pd

fastf1.Cache.enable_cache(r'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU Health Monitor')

# Load 2025 Bahrain GP Race session
session = fastf1.get_session(2025, 'Bahrain', 'R')
session.load()

print(session.drivers)

drivers = ['12', '63']  # Kimi Antonelli and George Russell

drivers = ['ANT', 'RUS']  # Replace with correct driver codes from session.drivers output

for driver in drivers:
    laps = session.laps.pick_drivers(driver)
    all_telemetry = []

    for idx, lap in laps.iterlaps():
        telemetry = lap.get_car_data()
        # Select columns of interest; adjust gear column name if needed
        cols = ['Time', 'Speed', 'RPM', 'Throttle', 'nGear', 'Brake', 'DRS']
        # Check if all columns exist, otherwise skip or handle
        existing_cols = [c for c in cols if c in telemetry.columns]
        telemetry = telemetry[existing_cols]
        telemetry['LapNumber'] = lap.LapNumber
        all_telemetry.append(telemetry)

    driver_telemetry = pd.concat(all_telemetry)
    file_path = os.path.join(r'C:\Users\berke\OneDrive\Masaüstü\GitHub\PU Health Monitor', f'{driver}_Bahrain_2025_Race_Data.csv')
    driver_telemetry.to_csv(file_path, index=False)
    print(f"Exported telemetry CSV for {driver} to {file_path}")
