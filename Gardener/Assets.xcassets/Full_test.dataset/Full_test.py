import os
import certifi
import warnings
from datetime import datetime
import calendar
import glob
import pandas as pd
from math import exp
import requests
import csv
from io import BytesIO
from PIL import Image, ImageTk
import tkinter as tk
from tkinter import messagebox, simpledialog

# OpenWeather API Key (replace with your own if needed)
OPENWEATHER_API_KEY = "8ab060ad06b4fa2accd41a4f8e646025"

# ----------------------- API and Data Functions -----------------------

def fetch_api(url, params=None):
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Request error: {url} - {e}")
    except requests.exceptions.JSONDecodeError:
        print(f"⚠️ JSON parsing failed: {url}")
    return None

def get_alternative_precipitation(lat, lon, start_date, end_date):
    start_date_alt = f"{start_date[:4]}-{start_date[4:6]}-{start_date[6:]}"
    end_date_alt = f"{end_date[:4]}-{end_date[4:6]}-{end_date[6:]}"
    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date_alt,
        "end_date": end_date_alt,
        "daily": "precipitation_sum",
        "timezone": "auto"
    }
    response = fetch_api(url, params)
    if response and "daily" in response and "precipitation_sum" in response["daily"]:
        precip_values = response["daily"]["precipitation_sum"]
        if precip_values:
            valid_values = [v for v in precip_values if v is not None]
            if valid_values:
                return sum(valid_values)
    return "No data"

def get_meteostat_precipitation(lat, lon, month, year):
    start_date = datetime(year, month, 1)
    last_day = calendar.monthrange(year, month)[1]
    end_date = datetime(year, month, last_day)
    from meteostat import Point, Daily  # local import
    location = Point(lat, lon)
    data = Daily(location, start_date, end_date).fetch()
    if data.empty:
        return "No data"
    return data['prcp'].sum()

def get_climate_data(lat, lon, month, year, max_years_back=5):
    now = datetime.now()
    current_year = now.year
    current_month = now.month
    if year > current_year or (year == current_year and month > current_month):
        return {"Error": "Input month/year is in the future. Please provide a month up to the current month."}
    first_day = 1
    last_day = now.day if (year == current_year and month == current_month) else calendar.monthrange(year, month)[1]
    attempts = 0
    adjusted_year = year
    while attempts < max_years_back:
        start_date_str = datetime(adjusted_year, month, first_day).strftime("%Y%m%d")
        end_date_str = datetime(adjusted_year, month, last_day).strftime("%Y%m%d")
        print(f"Fetching NASA POWER data for {start_date_str} to {end_date_str}...")
        params = {
            "parameters": "T2M,PRECTOT",
            "community": "RE",
            "longitude": lon,
            "latitude": lat,
            "start": start_date_str,
            "end": end_date_str,
            "format": "JSON"
        }
        climate_response = fetch_api("https://power.larc.nasa.gov/api/temporal/daily/point", params)
        if (climate_response and "properties" in climate_response and
            "parameter" in climate_response["properties"]):
            parameters = climate_response["properties"]["parameter"]
            t2m_data = parameters.get("T2M", {})
            prectot_data = parameters.get("PRECTOT", {})
            valid_t2m = [v for v in t2m_data.values() if v != -999.0]
            valid_prectot = [v for v in prectot_data.values() if v != -999.0]
            avg_t2m = sum(valid_t2m) / len(valid_t2m) if valid_t2m else "No data"
            if valid_prectot:
                total_prectot = sum(valid_prectot)
            else:
                print("NASA precipitation missing; trying Open-Meteo...")
                total_prectot = get_alternative_precipitation(lat, lon, start_date_str, end_date_str)
                if total_prectot == "No data":
                    print("Open-Meteo data missing; trying Meteostat as third alternative...")
                    total_prectot = get_meteostat_precipitation(lat, lon, month, adjusted_year)
            if avg_t2m != "No data" or total_prectot != "No data":
                return {
                    "Date Range": f"{start_date_str} to {end_date_str}",
                    "Average Temperature (T2M)": avg_t2m,
                    "Total Precipitation (PRECTOT)": total_prectot
                }
        adjusted_year -= 1
        attempts += 1
    return {"Error": f"No climate data for month {month} in past {max_years_back} years from {year}."}

def get_weather_data(lat, lon):
    url = "https://api.openweathermap.org/data/2.5/weather"
    params = {"lat": lat, "lon": lon, "appid": OPENWEATHER_API_KEY, "units": "metric"}
    return fetch_api(url, params)

def get_soil_data(lat, lon, depth="0-5cm"):
    url = "https://rest.isric.org/soilgrids/v2.0/properties/query"
    properties = ["phh2o", "soc", "clay", "silt", "sand", "cec", "cfvo"]
    soil_data = {}
    for prop in properties:
        params = {"lat": lat, "lon": lon, "property": prop, "depth": depth, "value": "mean"}
        response = fetch_api(url, params)
        if response and "features" in response and len(response["features"]) > 0:
            soil_data[prop] = response["features"][0]["properties"].get(prop, {}).get(depth, {}).get("mean", None)
        else:
            soil_data[prop] = None
    return soil_data

def get_terrain_data(lat, lon):
    url = "https://api.opentopodata.org/v1/srtm90m"
    params = {"locations": f"{lat},{lon}"}
    return fetch_api(url, params)

def get_location_info(lat, lon, month, year):
    report = {}
    report["Climate Data"] = get_climate_data(lat, lon, month, year)
    weather_response = get_weather_data(lat, lon)
    if weather_response and "main" in weather_response:
        main = weather_response["main"]
        report["Weather Data"] = {
            "Location": weather_response.get("name", "Unknown"),
            "Temperature": main.get("temp", "No data"),
            "Humidity": main.get("humidity", "No data"),
            "Pressure": main.get("pressure", "No data")
        }
    else:
        report["Weather Data"] = "No weather data retrieved."
    soil_response = get_soil_data(lat, lon)
    report["Soil Data (Depth 0-5cm)"] = soil_response if soil_response else "No soil data retrieved."
    terrain_response = get_terrain_data(lat, lon)
    if terrain_response and "results" in terrain_response and len(terrain_response["results"]) > 0:
        elevation = terrain_response["results"][0].get("elevation", "No data")
        report["Elevation Data"] = {"Elevation (meters)": elevation}
    else:
        report["Elevation Data"] = "No elevation data retrieved."
    return report

def export_report_to_csv(report, filepath='/Users/michael_z/Downloads/location_data_report.csv'):
    try:
        with open(filepath, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['Section', 'Key', 'Value'])
            for section, data in report.items():
                if isinstance(data, dict):
                    for key, value in data.items():
                        writer.writerow([section, key, '' if value is None else str(value)])
                else:
                    writer.writerow([section, '', str(data)])
        print(f"Successfully exported report to {filepath}")
    except Exception as e:
        print(f"Error exporting report: {e}")

def read_report_from_csv(filepath='/Users/michael_z/Downloads/location_data_report.csv'):
    report = {}
    try:
        with open(filepath, 'r') as csvfile:
            reader = csv.reader(csvfile)
            next(reader)  # Skip header
            for row in reader:
                section, key, value = row
                if section not in report:
                    report[section] = {}
                if key:
                    report[section][key] = value if value else None
                else:
                    report[section] = value if value else None
    except Exception as e:
        print(f"Error reading CSV: {e}")
    return report

def load_local_crop_datasets(folder_path):
    csv_files = glob.glob(os.path.join(folder_path, '*.csv'))
    if not csv_files:
        print(f"No CSV files found in {folder_path}")
        return None
    dfs = [pd.read_csv(file) for file in csv_files if not pd.read_csv(file).empty]
    if not dfs:
        return None
    df_combined = pd.concat(dfs, ignore_index=True)
    print(f"Combined DataFrame shape: {df_combined.shape}")
    return df_combined

def export_plant_counts(df, folder_path):
    total_plants = len(df)
    group_col = next((col for col in ['label', 'crop', 'common_name', 'plant_name'] if col in df.columns), None)
    if not group_col:
        raise KeyError(f"No suitable column found in {list(df.columns)}")
    counts = df[group_col].value_counts().to_dict()
    output_file = os.path.join(folder_path, "plant_count.txt")
    with open(output_file, "w") as f:
        f.write(f"Total number of plant rows: {total_plants}\n")
        f.write("Counts per crop:\n")
        for crop, count in counts.items():
            f.write(f"{crop}: {count}\n")
    print(f"Plant counts exported to {output_file}")

def compute_optimal_conditions(df):
    group_col = next((col for col in ['label', 'crop', 'common_name', 'plant_name'] if col in df.columns), None)
    if not group_col:
        raise KeyError(f"No suitable column found in {list(df.columns)}")
    groups = df.groupby(group_col)
    optimal = {
        crop: {
            'T_opt': group['Temperature'].mean(),
            'H_opt': group['Humidity'].mean(),
            'pH_opt': group['pH'].mean(),
            'AP_opt': group['Rainfall'].mean()
        }
        for crop, group in groups
    }
    return optimal

def plant_fitness(sensor, optimal, sigmas, weights):
    T_opt = optimal['T_opt']
    H_opt = optimal['H_opt']
    pH_opt = optimal['pH_opt']
    AP_opt = optimal['AP_opt']
    P_opt = 1013
    T_avg_opt = T_opt
    diff_T = (sensor['T'] - T_opt)**2 / (2 * sigmas['sigma_T']**2)
    diff_H = (sensor['H'] - H_opt)**2 / (2 * sigmas['sigma_H']**2)
    diff_P = (sensor['P'] - P_opt)**2 / (2 * sigmas['sigma_P']**2)
    diff_Tavg = (sensor['T_avg'] - T_avg_opt)**2 / (2 * sigmas['sigma_Tavg']**2)
    diff_AP = (sensor['AP'] - AP_opt)**2 / (2 * sigmas['sigma_AP']**2)
    diff_pH = (sensor['pH'] - pH_opt)**2 / (2 * sigmas['sigma_pH']**2)
    exponent = (weights['w_T'] * diff_T +
                weights['w_H'] * diff_H +
                weights['w_P'] * diff_P +
                weights['w_Tavg'] * diff_Tavg +
                weights['w_AP'] * diff_AP +
                weights['w_pH'] * diff_pH)
    return exp(-exponent)

def get_sensor_data_from_report(report):
    sensor_data = {}
    keys = {
        'T': ('Weather Data', 'Temperature'),
        'H': ('Weather Data', 'Humidity'),
        'P': ('Weather Data', 'Pressure'),
        'T_avg': ('Climate Data', 'Average Temperature (T2M)'),
        'AP': ('Climate Data', 'Total Precipitation (PRECTOT)'),
        'pH': ('Soil Data (Depth 0-5cm)', 'phh2o')
    }
    for key, (section, subkey) in keys.items():
        try:
            value = report.get(section, {}).get(subkey, None)
            sensor_data[key] = float(value) if value and value.strip() else None
        except (ValueError, TypeError):
            sensor_data[key] = None
    return sensor_data

def prompt_for_missing_data(sensor_data, prompts, valid_ranges):
    for key in sensor_data:
        if sensor_data[key] is None:
            while True:
                answer = simpledialog.askstring("Input", prompts[key])
                if answer is None:
                    messagebox.showerror("Error", "Input cancelled. Please provide a value.")
                    continue
                try:
                    val = float(answer)
                    min_val, max_val = valid_ranges[key]
                    if not (min_val <= val <= max_val):
                        messagebox.showerror("Error", f"Value {val} outside range ({min_val}, {max_val}).")
                        continue
                    sensor_data[key] = val
                    break
                except (ValueError, TypeError):
                    messagebox.showerror("Error", "Invalid input. Please enter a number.")
    return sensor_data

def recommend_crop(sensor_data, optimal_conditions, sigmas, weights):
    crop_fitness = {crop: plant_fitness(sensor_data, optimal, sigmas, weights)
                    for crop, optimal in optimal_conditions.items()}
    best_crop = max(crop_fitness, key=crop_fitness.get)
    return best_crop, crop_fitness[best_crop], crop_fitness

def look_at_image(optimal_crop):
    try:
        df_numbers = pd.read_csv('/Users/michael_z/Downloads/Plant Database/numbers_updated.csv')
    except Exception as e:
        messagebox.showerror("Error", f"Failed to open CSV file: {e}")
        return
    row = df_numbers[df_numbers['plant_name'] == optimal_crop]
    if row.empty:
        messagebox.showerror("Error", f"Plant '{optimal_crop}' not found in CSV.")
        return
    image_url = row.iloc[0].get('image_url')
    if pd.isnull(image_url) or not image_url:
        messagebox.showerror("Error", f"No image URL for {optimal_crop}.")
        return
    try:
        response = requests.get(image_url, timeout=10)
        response.raise_for_status()
        image_data = BytesIO(response.content)
        pil_image = Image.open(image_data)
    except Exception as e:
        messagebox.showerror("Error", f"Failed to load image: {e}")
        return
    img_win = tk.Toplevel()
    img_win.title(f"Image of {optimal_crop}")
    max_width, max_height = 600, 600
    pil_image.thumbnail((max_width, max_height))
    img = ImageTk.PhotoImage(pil_image)
    img_win.image = img  # Prevent garbage collection
    lbl_img = tk.Label(img_win, image=img)
    lbl_img.pack(padx=10, pady=10)

# ----------------------- GUI Classes (Pages) -----------------------

class OutdoorsPage(tk.Frame):
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        self.controller = controller
        # Reduced spacing to more closely match original look
        label = tk.Label(self, text="Are you planting outdoors?")
        label.pack(pady=5)
        btn_yes = tk.Button(self, text="Yes", width=15, command=lambda: self.set_outdoors(True))
        btn_yes.pack(side=tk.LEFT, padx=10)
        btn_no = tk.Button(self, text="No", width=15, command=lambda: self.set_outdoors(False))
        btn_no.pack(side=tk.RIGHT, padx=10)
    def set_outdoors(self, flag):
        self.controller.planting_outdoors = flag
        self.controller.show_frame("ModeSelectionPage")

class ModeSelectionPage(tk.Frame):
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        self.controller = controller
        btn_optimal = tk.Button(self, text="Optimal Solution", width=20,
                                command=lambda: self.select_mode("optimal"))
        btn_optimal.grid(row=0, column=0, padx=20, pady=10)
        label_optimal = tk.Label(self, text="Helps you find the best plant")
        label_optimal.grid(row=1, column=0)
        btn_selective = tk.Button(self, text="Selective Solution", width=20,
                                  command=lambda: self.select_mode("selective"))
        btn_selective.grid(row=0, column=1, padx=20, pady=10)
        label_selective = tk.Label(self, text="Helps you find the best plant of your own choosing")
        label_selective.grid(row=1, column=1)
        back_btn = tk.Button(self, text="Back", width=15,
                             command=lambda: controller.show_frame("OutdoorsPage"))
        back_btn.grid(row=2, column=0, columnspan=2, pady=10)
    def select_mode(self, mode):
        self.controller.solution_mode = mode
        if self.controller.planting_outdoors:
            self.controller.show_frame("LocationInputPage")
        else:
            self.controller.show_frame("ManualInputPage")
        if mode == "selective":
            self.controller.open_selective_window()

class LocationInputPage(tk.Frame):
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        self.controller = controller
        label = tk.Label(self, text="Enter Location Information")
        label.pack(pady=10)
        self.lat_entry = tk.Entry(self)
        self.lat_entry.pack(pady=5)
        self.lon_entry = tk.Entry(self)
        self.lon_entry.pack(pady=5)
        self.month_entry = tk.Entry(self)
        self.month_entry.pack(pady=5)
        self.year_entry = tk.Entry(self)
        self.year_entry.pack(pady=5)
        submit_btn = tk.Button(self, text="Submit", command=self.on_submit)
        submit_btn.pack(pady=5)
        back_btn = tk.Button(self, text="Back",
                             command=lambda: controller.show_frame("ModeSelectionPage"))
        back_btn.pack(pady=5)
    def on_submit(self):
        try:
            lat = float(self.lat_entry.get())
            lon = float(self.lon_entry.get())
            month = int(self.month_entry.get())
            year = int(self.year_entry.get())
        except ValueError:
            messagebox.showerror("Error", "Please enter numeric values for location.")
            return
        report = get_location_info(lat, lon, month, year)
        csv_path = '/Users/michael_z/Downloads/location_data_report.csv'
        export_report_to_csv(report, csv_path)
        report_from_csv = read_report_from_csv(csv_path)
        prompts = {
            'T': "Enter instantaneous temperature (°C): ",
            'H': "Enter ambient humidity (%): ",
            'P': "Enter atmospheric pressure (hPa): ",
            'T_avg': "Enter monthly average temperature (°C): ",
            'AP': "Enter total precipitation (mm): ",
            'pH': "Enter soil pH: "
        }
        valid_ranges = {
            'T': (-50, 60),
            'H': (0, 100),
            'P': (900, 1100),
            'T_avg': (-50, 60),
            'AP': (0, 1000),
            'pH': (0, 14)
        }
        sensor_data = get_sensor_data_from_report(report_from_csv)
        sensor_data = prompt_for_missing_data(sensor_data, prompts, valid_ranges)
        self.controller.process_recommendation(sensor_data)

class ManualInputPage(tk.Frame):
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        self.controller = controller
        label = tk.Label(self, text="Enter Sensor Data Manually")
        label.pack(pady=10)
        self.entry_T = tk.Entry(self)
        self.entry_T.pack(pady=5)
        self.entry_H = tk.Entry(self)
        self.entry_H.pack(pady=5)
        self.entry_P = tk.Entry(self)
        self.entry_P.pack(pady=5)
        self.entry_Tavg = tk.Entry(self)
        self.entry_Tavg.pack(pady=5)
        self.entry_AP = tk.Entry(self)
        self.entry_AP.pack(pady=5)
        self.entry_pH = tk.Entry(self)
        self.entry_pH.pack(pady=5)
        submit_btn = tk.Button(self, text="Submit", command=self.on_submit)
        submit_btn.pack(pady=5)
        back_btn = tk.Button(self, text="Back",
                             command=lambda: controller.show_frame("ModeSelectionPage"))
        back_btn.pack(pady=5)
    def on_submit(self):
        try:
            sensor_data = {
                'T': float(self.entry_T.get()),
                'H': float(self.entry_H.get()),
                'P': float(self.entry_P.get()),
                'T_avg': float(self.entry_Tavg.get()),
                'AP': float(self.entry_AP.get()),
                'pH': float(self.entry_pH.get())
            }
        except ValueError:
            messagebox.showerror("Error", "Please enter valid numeric sensor values.")
            return
        self.controller.process_recommendation(sensor_data)

class ResultPage(tk.Frame):
    def __init__(self, parent, controller):
        tk.Frame.__init__(self, parent)
        self.controller = controller
        self.text_result = tk.Text(self, height=15, width=50)
        self.text_result.pack(padx=5, pady=5)
        self.lbl_recommendation = tk.Label(self, text="", font=("Helvetica", 14, "bold"), fg="green")
        self.lbl_recommendation.pack(pady=5)
        btn_image = tk.Button(self, text="What does it look like?",
                              command=lambda: look_at_image(self.controller.optimal_crop))
        btn_image.pack(pady=5)
        back_btn = tk.Button(self, text="Back",
                             command=lambda: controller.show_frame("ModeSelectionPage"))
        back_btn.pack(pady=5)
        exit_btn = tk.Button(self, text="Exit", command=controller.destroy)
        exit_btn.pack(pady=5)
    def set_result(self, crop, fitness):
        self.text_result.delete(1.0, tk.END)
        self.text_result.insert(tk.END, "Optimal Crop Recommendation:\n")
        self.text_result.insert(tk.END, f"{crop} (Fitness Score: {fitness:.4f})\n")
        self.lbl_recommendation.config(text=f"Recommended Crop: {crop} (Score: {fitness:.4f})")

# ----------------------- Main Application Class -----------------------

class App(tk.Tk):
    def __init__(self):
        tk.Tk.__init__(self)
        self.title("Crop Recommendation System")
        self.geometry("600x600")
        self.solution_mode = None
        self.selected_plants = []  # For selective mode
        self.planting_outdoors = None  # True if outdoors, False if not
        self.optimal_crop = None
        container = tk.Frame(self)
        container.pack(side="top", fill="both", expand=True)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)
        self.frames = {}
        for F in (OutdoorsPage, ModeSelectionPage, LocationInputPage, ManualInputPage, ResultPage):
            page_name = F.__name__
            frame = F(parent=container, controller=self)
            self.frames[page_name] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        self.show_frame("OutdoorsPage")
    def show_frame(self, page_name):
        frame = self.frames[page_name]
        frame.tkraise()
    def open_selective_window(self):
        sel_win = tk.Toplevel(self)
        sel_win.title("Select Plants")
        sel_win.geometry("500x400")
        avail_frame = tk.Frame(sel_win)
        avail_frame.pack(side=tk.LEFT, padx=10, fill=tk.BOTH, expand=True)
        tk.Label(avail_frame, text="Available Plants").pack()
        search_var = tk.StringVar()
        search_entry = tk.Entry(avail_frame, textvariable=search_var)
        search_entry.pack(pady=5, fill=tk.X)
        avail_listbox = tk.Listbox(avail_frame, selectmode=tk.MULTIPLE)
        avail_listbox.pack(fill=tk.BOTH, expand=True)
        avail_scroll = tk.Scrollbar(avail_frame, orient=tk.VERTICAL, command=avail_listbox.yview)
        avail_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        avail_listbox.config(yscrollcommand=avail_scroll.set)
        sel_frame = tk.Frame(sel_win)
        sel_frame.pack(side=tk.RIGHT, padx=10, fill=tk.BOTH, expand=True)
        tk.Label(sel_frame, text="Selected Plants").pack()
        sel_listbox = tk.Listbox(sel_frame, bg="light blue")
        sel_listbox.pack(fill=tk.BOTH, expand=True)
        sel_scroll = tk.Scrollbar(sel_frame, orient=tk.VERTICAL, command=sel_listbox.yview)
        sel_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        sel_listbox.config(yscrollcommand=sel_scroll.set)
        folder_path = '/Users/michael_z/Downloads/Plant Database'
        df = load_local_crop_datasets(folder_path)
        if df is None:
            messagebox.showerror("Error", "No crop data found for selection.")
            sel_win.destroy()
            return
        group_col = next((col for col in ['label', 'crop', 'common_name', 'plant_name'] if col in df.columns), None)
        all_plants = sorted(df[group_col].unique())
        def update_avail_list(*args):
            search_text = search_var.get().lower()
            avail_listbox.delete(0, tk.END)
            for plant in all_plants:
                if search_text in str(plant).lower():
                    avail_listbox.insert(tk.END, plant)
        search_var.trace("w", update_avail_list)
        update_avail_list()
        def add_selected():
            indices = avail_listbox.curselection()
            for idx in indices:
                plant = avail_listbox.get(idx)
                if plant not in sel_listbox.get(0, tk.END):
                    sel_listbox.insert(tk.END, plant)
        btn_add = tk.Button(sel_win, text="Add >>", command=add_selected)
        btn_add.pack(pady=5)
        def remove_selected():
            for idx in reversed(sel_listbox.curselection()):
                sel_listbox.delete(idx)
        btn_remove = tk.Button(sel_win, text="<< Remove", command=remove_selected)
        btn_remove.pack(pady=5)
        def submit_selection():
            if sel_listbox.size() == 0:
                messagebox.showerror("Error", "Please select at least one plant.")
                return
            self.selected_plants = list(sel_listbox.get(0, tk.END))
            sel_win.destroy()
        btn_submit_sel = tk.Button(sel_win, text="Submit Selection", command=submit_selection)
        btn_submit_sel.pack(pady=10)
        btn_back_sel = tk.Button(sel_win, text="Back", command=sel_win.destroy)
        btn_back_sel.pack(pady=5)
    def process_recommendation(self, sensor_data):
        folder_path = '/Users/michael_z/Downloads/Plant Database'
        df = load_local_crop_datasets(folder_path)
        if df is None:
            messagebox.showerror("Error", "No crop data found.")
            return
        export_plant_counts(df, folder_path)
        if self.solution_mode == "selective" and self.selected_plants:
            group_col = next((col for col in ['label', 'crop', 'common_name', 'plant_name'] if col in df.columns), None)
            df = df[df[group_col].isin(self.selected_plants)]
            if df.empty:
                messagebox.showerror("Error", "No matching crop data found for the selected plants.")
                return
        optimal_conditions = compute_optimal_conditions(df)
        sigmas = {
            'sigma_T': 2.0,
            'sigma_H': 10.0,
            'sigma_P': 10.0,
            'sigma_Tavg': 2.0,
            'sigma_AP': 20.0,
            'sigma_pH': 0.5
        }
        weights = {
            'w_T': 0.35,
            'w_H': 0.30,
            'w_P': 0.05,
            'w_Tavg': 0.15,
            'w_AP': 0.10,
            'w_pH': 0.05
        }
        best_crop, best_fitness, _ = recommend_crop(sensor_data, optimal_conditions, sigmas, weights)
        self.optimal_crop = best_crop
        result_page = self.frames["ResultPage"]
        result_page.set_result(best_crop, best_fitness)
        self.show_frame("ResultPage")

if __name__ == "__main__":
    warnings.filterwarnings("ignore", category=FutureWarning, module="meteostat.core.loader")
    os.environ['SSL_CERT_FILE'] = certifi.where()
    app = App()
    app.mainloop()