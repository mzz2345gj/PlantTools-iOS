import SwiftUI
import CoreLocation
import UserNotifications

// MARK: - Models

struct SensorData: Codable {
    let T: Double?      // instantaneous temperature
    let H: Double?      // ambient humidity
    let P: Double?      // atmospheric pressure
    let T_avg: Double?  // monthly average temperature
    let AP: Double?     // total precipitation
    let pH: Double?     // soil pH
}

struct CropRecommendation: Codable {
    let text: String
    let image_url: String?
}

struct PlantAnalysisResponse: Codable {
    let analysis: String
    let diseases: String
    let remedy: String
}

// MARK: - Watering Recommendation Models

struct WateringPot: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var plantName: String = ""
    var shape: String = "Circular" // or "Rectangular"
    var radius: Double? = nil // cm
    var length: Double? = nil // cm
    var width: Double? = nil // cm
}

struct WateringYardPlant: Identifiable, Codable {
    var id = UUID()
    var name: String = ""
    var area: Double = 0.0 // m^2
}

struct WateringYard: Codable {
    var length: Double = 0.0 // m
    var width: Double = 0.0 // m
    var plants: [WateringYardPlant] = []
}

struct WateringAPIResponse: Codable {
    let latitude: Double
    let longitude: Double
    let watering_start: String
    let watering_end: String
    let dailySchedule: [WateringDay]
    let soilType: String?
    let yardPlantType: String?
}

struct WateringDay: Codable {
    let date: String
    let items: [WateringDayItem]
}

struct WateringDayItem: Codable {
    let container: String
    let container_type: String
    let plant: String
    let amount: Double
    let frequency_min: Int
    let frequency_max: Int
}

// MARK: - Localization Manager

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
        }
    }
    
    let translations: [String: [String: String]] = [
        "Settings": ["en": "Settings", "zh": "设置"],
        "Home": ["en": "Home", "zh": "主页"],
        "Grow": ["en": "Grow", "zh": "种植"],
        "Check": ["en": "Check", "zh": "检查"],
        "Hello, Gardener!": ["en": "Hello, Gardener!", "zh": "你好，园丁！"],
        "Let's make your plants happy": ["en": "Let's make your plants happy", "zh": "让我们让你的植物快乐"],
        "Grow Easy": ["en": "Grow Easy", "zh": "轻松种植"],
        "Plant Checkup": ["en": "Plant Checkup", "zh": "植物检查"],
        "Language": ["en": "Language", "zh": "语言"],
        "Select Language": ["en": "Select Language", "zh": "选择语言"],
        "English": ["en": "English", "zh": "英语"],
        "Chinese": ["en": "Chinese", "zh": "中文"],
        "Look & Feel": ["en": "Look & Feel", "zh": "外观与感觉"],
        "Dark Mode": ["en": "Dark Mode", "zh": "深色模式"],
        "Search Plants": ["en": "Search Plants", "zh": "搜索植物"],
        "No plants found.": ["en": "No plants found.", "zh": "未找到植物。"],
        "Select Plant": ["en": "Select Plant", "zh": "选择植物"],
        "Plant list file not found.": ["en": "Plant list file not found.", "zh": "未找到植物列表文件。"],
        "Failed to load plants: ": ["en": "Failed to load plants: ", "zh": "加载植物失败："],
        "Select Plants": ["en": "Select Plants", "zh": "选择植物"],
        "Done": ["en": "Done", "zh": "完成"],
        "Temperature": ["en": "Temperature", "zh": "温度"],
        "Humidity": ["en": "Humidity", "zh": "湿度"],
        "Pressure": ["en": "Pressure", "zh": "压力"],
        "Avg Temperature": ["en": "Avg Temperature", "zh": "平均温度"],
        "Precipitation": ["en": "Precipitation", "zh": "降水量"],
        "Soil pH": ["en": "Soil pH", "zh": "土壤pH"],
        "Edit Sensor Data": ["en": "Edit Sensor Data", "zh": "编辑传感器数据"],
        "Your Location": ["en": "Your Location", "zh": "位置"],
        "Find My Location": ["en": "Find My Location", "zh": "找到我的位置"],
        "Latitude": ["en": "Latitude", "zh": "纬度"],
        "Longitude": ["en": "Longitude", "zh": "经度"],
        "Grab Weather Data": ["en": "Grab Weather Data", "zh": "获取天气数据"],
        "Pick Your Plants": ["en": "Pick Your Plants", "zh": "选择您的植物"],
        "No plants yet--add some!": ["en": "No plants yet--add some!", "zh": "还没有植物——添加一些！"],
        "Get Plant Ideas": ["en": "Get Plant Ideas", "zh": "获取植物建议"],
        "Fetching weather...": ["en": "Fetching weather...", "zh": "正在获取天气..."],
        "Finding plants...": ["en": "Finding plants...", "zh": "正在查找植物..."],
        "Oops!": ["en": "Oops!", "zh": "哎呀！"],
        "Got It": ["en": "Got It", "zh": "知道了"],
        "Connection issue.": ["en": "Connection issue.", "zh": "连接问题。"],
        "Enter a valid location.": ["en": "Enter a valid location.", "zh": "输入有效的位置。"],
        "Weather fetch failed: ": ["en": "Weather fetch failed: ", "zh": "获取天气失败："],
        "No weather data.": ["en": "No weather data.", "zh": "没有天气数据。"],
        "Error decoding weather data.": ["en": "Error decoding weather data.", "zh": "解码天气数据错误。"],
        "Connection error or location required.": ["en": "Connection error or location required.", "zh": "连接错误或需要位置。"],
        "Data preparation failed.": ["en": "Data preparation failed.", "zh": "数据准备失败。"],
        "Network error: ": ["en": "Network error: ", "zh": "网络错误："],
        "No recommendation received.": ["en": "No recommendation received.", "zh": "未收到建议。"],
        "Error decoding recommendation.": ["en": "Error decoding recommendation.", "zh": "解码建议错误。"],
        "Your Plant Recommendation": ["en": "Your Plant Recommendation", "zh": "您的植物建议"],
        "Recommendation": ["en": "Recommendation", "zh": "建议"],
        "Tap to pick a plant photo": ["en": "Tap to pick a plant photo", "zh": "点击选择植物照片"],
        "Check My Plant": ["en": "Check My Plant", "zh": "检查我的植物"],
        "Checking your plant...": ["en": "Checking your plant...", "zh": "正在检查您的植物..."],
        "What We Found": ["en": "What We Found", "zh": "我们发现的"],
        "Possible Issues": ["en": "Possible Issues", "zh": "可能的问题"],
        "See Fix": ["en": "See Fix", "zh": "查看修复"],
        "Photo or connection issue.": ["en": "Photo or connection issue.", "zh": "照片或连接问题。"],
        "Upload failed: ": ["en": "Upload failed: ", "zh": "上传失败："],
        "No data received.": ["en": "No data received.", "zh": "未收到数据。"],
        "Error decoding analysis.": ["en": "Error decoding analysis.", "zh": "解码分析错误。"],
        "Your Plant Fix": ["en": "Your Plant Fix", "zh": "您的植物修复"],
        "Fix It": ["en": "Fix It", "zh": "修复它"],
        "Tech Stuff": ["en": "Tech Stuff", "zh": "技术信息"],
        "Server: ": ["en": "Server: ", "zh": "服务器："],
        "Photo Source": ["en": "Photo Source", "zh": "照片来源"],
        "Snap a Pic": ["en": "Snap a Pic", "zh": "拍张照片"],
        "From Library": ["en": "From Library", "zh": "从图库选择"],
        "Please enable location in Settings.": ["en": "Please enable location in Settings.", "zh": "请在设置中启用位置。"],
        "Location permission needed.": ["en": "Location permission needed.", "zh": "需要位置权限。"],
        "Oops! We couldn't fetch your location.": ["en": "Oops! We couldn't fetch your location.", "zh": "哎呀！我们无法获取您的位置。"],
        "Disease detection only supports the following plants: Strawberry, Grape, Blueberry, Corn, Peach, Pepper, Raspberry, Tomato, Cherry, Apple, Potato, Soybean": ["en": "Disease detection only supports the following plants: Strawberry, Grape, Blueberry, Corn, Peach, Pepper, Raspberry, Tomato, Cherry, Apple, Potato, Soybean", "zh": "疾病检测仅支持以下植物：草莓、葡萄、蓝莓、玉米、桃子、辣椒、树莓、番茄、樱桃、苹果、土豆、大豆"],
        "Get plant recommendations": ["en": "Get plant recommendations", "zh": "获取植物推荐"],
        "Check plant health": ["en": "Check plant health", "zh": "检查植物健康"],
        "Quick Tips": ["en": "Quick Tips", "zh": "快速提示"],
        "Watering": ["en": "Watering", "zh": "浇水"],
        "Check soil moisture before watering": ["en": "Check soil moisture before watering", "zh": "浇水前检查土壤湿度"],
        "Sunlight": ["en": "Sunlight", "zh": "阳光"],
        "Most plants need 6-8 hours of light": ["en": "Most plants need 6-8 hours of light", "zh": "大多数植物需要6-8小时光照"],
        "Keep plants away from drafts": ["en": "Keep plants away from drafts", "zh": "让植物远离通风处"],
        "Watering Plan": ["en": "Watering Plan", "zh": "浇水计划"],
        "Get daily watering CSV": ["en": "Get daily watering CSV", "zh": "获取每日浇水CSV"],
        "Pots": ["en": "Pots", "zh": "花盆"],
        "Pot Name": ["en": "Pot Name", "zh": "花盆名称"],
        "Plant Name": ["en": "Plant Name", "zh": "植物名称"],
        "Shape": ["en": "Shape", "zh": "形状"],
        "Circular": ["en": "Circular", "zh": "圆形"],
        "Rectangular": ["en": "Rectangular", "zh": "矩形"],
        "Radius (cm)": ["en": "Radius (cm)", "zh": "半径 (厘米)"],
        "Length (cm)": ["en": "Length (cm)", "zh": "长度 (厘米)"],
        "Width (cm)": ["en": "Width (cm)", "zh": "宽度 (厘米)"],
        "Add Pot": ["en": "Add Pot", "zh": "添加花盆"],
        "Yard": ["en": "Yard", "zh": "院子"],
        "Length (m)": ["en": "Length (m)", "zh": "长度 (米)"],
        "Width (m)": ["en": "Width (m)", "zh": "宽度 (米)"],
        "Plants in Yard": ["en": "Plants in Yard", "zh": "院子里的植物"],
        "Area (m²)": ["en": "Area (m²)", "zh": "面积 (平方米)"],
        "Add Yard Plant": ["en": "Add Yard Plant", "zh": "添加院子植物"],
        "Watering Period": ["en": "Watering Period", "zh": "浇水周期"],
        "Start Date": ["en": "Start Date", "zh": "开始日期"],
        "End Date": ["en": "End Date", "zh": "结束日期"],
        "Get Watering Plan": ["en": "Get Watering Plan", "zh": "获取浇水计划"],
        "Use Current Location": ["en": "Use Current Location", "zh": "使用当前位置"],
        "Manual Input": ["en": "Manual Input", "zh": "手动输入"],
        "Please enter latitude and longitude.": ["en": "Please enter latitude and longitude.", "zh": "请输入纬度和经度。"],
        "Download CSV": ["en": "Download CSV", "zh": "下载CSV"],
        "days of watering recommendations ready.": ["en": "days of watering recommendations ready.", "zh": "天的浇水建议已准备好。"],
        "Soil Type": ["en": "Soil Type", "zh": "土壤类型"],
        "Delete": ["en": "Delete", "zh": "删除"],
        "Required": ["en": "Required", "zh": "必填"],
        "Example: 31.23": ["en": "Example: 31.23", "zh": "示例: 31.23"],
        "Example: 121.47": ["en": "Example: 121.47", "zh": "示例: 121.47"],
        "CSV Preview": ["en": "CSV Preview", "zh": "CSV预览"],
        "Pinch to zoom the table.": ["en": "Pinch to zoom the table.", "zh": "用双指缩放表格。"],
        "CSV Table Header": ["en": "CSV Table Header", "zh": "CSV表头"],
        "CSV Table Preview": ["en": "CSV Table Preview", "zh": "CSV表格预览"],
        "Watering Plan Results": ["en": "Watering Plan Results", "zh": "浇水计划结果"],
        "Add at least one pot or leave empty if not needed.": ["en": "Add at least one pot or leave empty if not needed.", "zh": "请至少添加一个花盆，或如不需要可留空。"],
        "Enter latitude": ["en": "Enter latitude", "zh": "输入纬度"],
        "Enter longitude": ["en": "Enter longitude", "zh": "输入经度"]
    ]
    
    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }
    
    func localizedString(for key: String) -> String {
        return translations[key]?[currentLanguage] ?? key
    }
}

// MARK: - API Configuration

class APIConfiguration: ObservableObject {
    @Published var baseURL: String = "https://gardenerflask.xyz"
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @AppStorage("accentColor") var accentColor: String = "blue"
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    var currentAccentColor: Color {
        switch accentColor {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.first {
            DispatchQueue.main.async {
                self.location = newLocation
                self.errorMessage = nil
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Oops! We couldn't fetch your location."
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.startUpdatingLocation()
            case .denied, .restricted:
                self.errorMessage = "Please enable location in Settings."
            default:
                break
            }
        }
    }
    
    func fetchCurrentLocation() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Location permission needed."
            }
        }
    }
}

// MARK: - ImagePicker & Helpers

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Plant Selection Views

struct SinglePlantSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedPlant: String
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []
    @State private var allPlants: [String] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                TextField(localizationManager.localizedString(for: "Search Plants"), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onChange(of: searchText) { filterPlants(query: $0) }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if searchResults.isEmpty {
                    Text(localizationManager.localizedString(for: "No plants found."))
                        .foregroundColor(.secondary)
                } else {
                    List(searchResults, id: \.self) { plant in
                        Button(action: {
                            selectedPlant = plant.capitalized
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(plant.capitalized)
                                Spacer()
                                if selectedPlant == plant.capitalized {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "Select Plant"))
            .onAppear { loadAllPlants() }
        }
    }
    
    func loadAllPlants() {
        guard let fileURL = Bundle.main.url(forResource: "unique_plant_names", withExtension: "csv") else {
            errorMessage = localizationManager.localizedString(for: "Plant list file not found.")
            return
        }
        do {
            let fileContents = try String(contentsOf: fileURL)
            let rows = fileContents.components(separatedBy: "\n")
            guard let header = rows.first,
                  let plantNameIndex = header.components(separatedBy: ",").firstIndex(of: "plant_name")
            else { return }
            
            let plants = rows.dropFirst().compactMap { row -> String? in
                let values = row.components(separatedBy: ",")
                return plantNameIndex < values.count &&
                    !values[plantNameIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? values[plantNameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil
            }
            allPlants = plants
            searchResults = plants
        } catch {
            errorMessage = localizationManager.localizedString(for: "Failed to load plants: ") + error.localizedDescription
        }
    }
    
    func filterPlants(query: String) {
        if query.isEmpty {
            searchResults = allPlants
        } else {
            searchResults = allPlants.filter { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

struct MultiplePlantSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedPlants: [String]
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText: String = ""
    @State private var searchResults: [String] = []
    @State private var allPlants: [String] = []
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                TextField(localizationManager.localizedString(for: "Search Plants"), text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onChange(of: searchText) { filterPlants(query: $0) }
                
                if let error = errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                if searchResults.isEmpty {
                    Text(localizationManager.localizedString(for: "No plants found.")).foregroundColor(.secondary)
                } else {
                    List(searchResults, id: \.self) { plant in
                        HStack {
                            Button(action: {
                                if selectedPlants.contains(plant) {
                                    selectedPlants.removeAll { $0 == plant }
                                } else {
                                    selectedPlants.append(plant)
                                }
                            }) {
                                Image(systemName: selectedPlants.contains(plant) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPlants.contains(plant) ? .green : .gray)
                            }
                            Text(plant)
                        }
                    }
                }
                
                Button(localizationManager.localizedString(for: "Done")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
                .padding()
            }
            .navigationTitle(localizationManager.localizedString(for: "Select Plants"))
            .onAppear { loadAllPlants() }
        }
    }
    
    func loadAllPlants() {
        guard let fileURL = Bundle.main.url(forResource: "unique_plant_names", withExtension: "csv") else {
            errorMessage = localizationManager.localizedString(for: "Plant list file not found.")
            return
        }
        do {
            let fileContents = try String(contentsOf: fileURL)
            let rows = fileContents.components(separatedBy: "\n")
            guard let header = rows.first,
                  let plantNameIndex = header.components(separatedBy: ",").firstIndex(of: "plant_name")
            else { return }
            
            let plants = rows.dropFirst().compactMap { row -> String? in
                let values = row.components(separatedBy: ",")
                return plantNameIndex < values.count &&
                    !values[plantNameIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? values[plantNameIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil
            }
            allPlants = plants
            searchResults = plants
        } catch {
            errorMessage = localizationManager.localizedString(for: "Failed to load plants: ") + error.localizedDescription
        }
    }
    
    func filterPlants(query: String) {
        if query.isEmpty {
            searchResults = allPlants
        } else {
            searchResults = allPlants.filter { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// MARK: - Editable Sensor Data Sheet

struct EditableSensorDataSheet: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var sensorData: SensorData
    
    @State private var temperature: String = ""
    @State private var humidity: String = ""
    @State private var pressure: String = ""
    @State private var avgTemperature: String = ""
    @State private var precipitation: String = ""
    @State private var soilPH: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Label(localizationManager.localizedString(for: "Temperature"), systemImage: "thermometer")) {
                    TextField("°C", text: $temperature)
                        .keyboardType(.decimalPad)
                }
                Section(header: Label(localizationManager.localizedString(for: "Humidity"), systemImage: "drop.fill")) {
                    TextField("%", text: $humidity)
                        .keyboardType(.decimalPad)
                }
                Section(header: Label(localizationManager.localizedString(for: "Pressure"), systemImage: "gauge")) {
                    TextField("hPa", text: $pressure)
                        .keyboardType(.decimalPad)
                }
                Section(header: Label(localizationManager.localizedString(for: "Avg Temperature"), systemImage: "sun.max.fill")) {
                    TextField("°C", text: $avgTemperature)
                        .keyboardType(.decimalPad)
                }
                Section(header: Label(localizationManager.localizedString(for: "Precipitation"), systemImage: "cloud.rain.fill")) {
                    TextField("mm", text: $precipitation)
                        .keyboardType(.decimalPad)
                }
                Section(header: Label(localizationManager.localizedString(for: "Soil pH"), systemImage: "leaf")) {
                    TextField("pH", text: $soilPH)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "Edit Sensor Data"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "Done")) {
                        sensorData = SensorData(
                            T: Double(temperature),
                            H: Double(humidity),
                            P: Double(pressure),
                            T_avg: Double(avgTemperature),
                            AP: Double(precipitation),
                            pH: Double(soilPH)
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                temperature = sensorData.T.map { String($0) } ?? ""
                humidity = sensorData.H.map { String($0) } ?? ""
                pressure = sensorData.P.map { String($0) } ?? ""
                avgTemperature = sensorData.T_avg.map { String($0) } ?? ""
                precipitation = sensorData.AP.map { String($0) } ?? ""
                soilPH = sensorData.pH.map { String($0) } ?? ""
            }
        }
    }
}

// MARK: - Plant Recommender Views

struct PlantRecommenderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var apiConfig: APIConfiguration
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var locationManager = LocationManager()
    @State private var manualLat: String = ""
    @State private var manualLon: String = ""
    @State private var sensorData = SensorData(T: nil, H: nil, P: nil, T_avg: nil, AP: nil, pH: nil)
    @State private var recommendation: CropRecommendation?
    @State private var isFetchingSensorData = false
    @State private var isFetchingRecommendation = false
    @State private var errorMessage: String?
    @State private var showingSensorDataSheet = false
    @State private var selectedPlants: [String] = []
    @State private var isPlantSelectionPresented = false
    @State private var showRecommendationSheet: Bool = false
    @Binding var selectedTab: Int
    
    var body: some View {
        Form {
            Section(header: Label(localizationManager.localizedString(for: "Your Location"), systemImage: "location.fill").foregroundColor(themeManager.currentAccentColor)) {
                Button(localizationManager.localizedString(for: "Find My Location")) {
                    fetchCurrentLocation()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
                .listRowBackground(Color.clear)
                
                if let loc = locationManager.location {
                    Text("Lat: \(loc.coordinate.latitude, specifier: "%.4f")").listRowBackground(Color.clear)
                    Text("Lon: \(loc.coordinate.longitude, specifier: "%.4f")").listRowBackground(Color.clear)
                } else {
                    TextField(localizationManager.localizedString(for: "Latitude"), text: $manualLat).keyboardType(.decimalPad).listRowBackground(Color.clear)
                    TextField(localizationManager.localizedString(for: "Longitude"), text: $manualLon).keyboardType(.decimalPad).listRowBackground(Color.clear)
                }
                
                if let error = locationManager.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).listRowBackground(Color.clear)
                }
            }
            
            Section {
                Button(localizationManager.localizedString(for: "Grab Weather Data")) {
                    let (lat, lon) = getCurrentLatLon()
                    if let lat = lat, let lon = lon {
                        fetchSensorData(lat: lat, lon: lon)
                    } else {
                        errorMessage = localizationManager.localizedString(for: "Enter a valid location.")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
                .listRowBackground(Color.clear)
            }
            
            Section(header: Label(localizationManager.localizedString(for: "Pick Your Plants"), systemImage: "leaf.fill").foregroundColor(themeManager.currentAccentColor)) {
                Button(localizationManager.localizedString(for: "Search Plants")) {
                    isPlantSelectionPresented = true
                }
                .foregroundColor(themeManager.currentAccentColor)
                .listRowBackground(Color.clear)
                
                if !selectedPlants.isEmpty {
                    ForEach(selectedPlants, id: \.self) { plant in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(plant)
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Text(localizationManager.localizedString(for: "No plants yet--add some!"))
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            
            Section {
                Button(localizationManager.localizedString(for: "Get Plant Ideas")) {
                    getCropRecommendation()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
                .disabled(isFetchingRecommendation)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(localizationManager.localizedString(for: "Grow Easy"))
        .navigationBarItems(leading:
            Button {
                selectedTab = 0
            } label: {
                Label(localizationManager.localizedString(for: "Home"), systemImage: "house.fill")
                    .foregroundColor(themeManager.currentAccentColor)
            }
        )
        .sheet(isPresented: $showingSensorDataSheet) {
            EditableSensorDataSheet(sensorData: $sensorData)
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $isPlantSelectionPresented) {
            MultiplePlantSelectionView(selectedPlants: $selectedPlants)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
        .sheet(isPresented: $showRecommendationSheet) {
            if let rec = recommendation {
                CropRecommendationSheet(recommendation: rec)
                    .environmentObject(themeManager)
                    .environmentObject(localizationManager)
            }
        }
        .overlay {
            if isFetchingSensorData || isFetchingRecommendation {
                VStack {
                    ProgressView()
                    Text(isFetchingSensorData ? localizationManager.localizedString(for: "Fetching weather...") : localizationManager.localizedString(for: "Finding plants..."))
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(10)
            }
        }
        .alert(isPresented: Binding<Bool>.constant(errorMessage != nil)) {
            Alert(title: Text(localizationManager.localizedString(for: "Oops!")),
                  message: Text(errorMessage ?? ""),
                  dismissButton: .default(Text(localizationManager.localizedString(for: "Got It"))) {
                    errorMessage = nil
                  })
        }
    }
    
    func fetchCurrentLocation() {
        locationManager.fetchCurrentLocation()
        if let location = locationManager.location {
            manualLat = String(format: "%.4f", location.coordinate.latitude)
            manualLon = String(format: "%.4f", location.coordinate.longitude)
        }
        errorMessage = locationManager.errorMessage
    }
    
    func getCurrentLatLon() -> (Double?, Double?) {
        if let loc = locationManager.location {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        } else if let lat = Double(manualLat), let lon = Double(manualLon) {
            return (lat, lon)
        }
        return (nil, nil)
    }
    
    func fetchSensorData(lat: Double, lon: Double) {
        guard let url = URL(string: "\(apiConfig.baseURL)/api/get_sensor_data?lat=\(lat)&lon=\(lon)&lang=\(localizationManager.currentLanguage)") else {
            errorMessage = localizationManager.localizedString(for: "Connection issue.")
            return
        }
        isFetchingSensorData = true
        errorMessage = nil
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isFetchingSensorData = false
                if let error = error {
                    self.errorMessage = localizationManager.localizedString(for: "Weather fetch failed: ") + error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = localizationManager.localizedString(for: "No weather data.")
                    return
                }
                do {
                    self.sensorData = try JSONDecoder().decode(SensorData.self, from: data)
                    self.showingSensorDataSheet = true
                } catch {
                    self.errorMessage = localizationManager.localizedString(for: "Error decoding weather data.")
                }
            }
        }.resume()
    }
    
    func getCropRecommendation() {
        let (lat, lon) = getCurrentLatLon()
        guard let lat = lat,
              let lon = lon,
              let url = URL(string: "\(apiConfig.baseURL)/api/crop_recommendation") else {
            errorMessage = localizationManager.localizedString(for: "Connection error or location required.")
            return
        }
        isFetchingRecommendation = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "T": sensorData.T ?? 0.0,
            "H": sensorData.H ?? 0.0,
            "P": sensorData.P ?? 0.0,
            "T_avg": sensorData.T_avg ?? 0.0,
            "AP": sensorData.AP ?? 0.0,
            "pH": sensorData.pH ?? 0.0,
            "lat": lat,
            "lon": lon,
            "selectedPlants": selectedPlants,
            "lang": localizationManager.currentLanguage
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            errorMessage = localizationManager.localizedString(for: "Data preparation failed.")
            isFetchingRecommendation = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isFetchingRecommendation = false
                if let error = error {
                    self.errorMessage = localizationManager.localizedString(for: "Network error: ") + error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = localizationManager.localizedString(for: "No recommendation received.")
                    return
                }
                do {
                    self.recommendation = try JSONDecoder().decode(CropRecommendation.self, from: data)
                    self.showRecommendationSheet = true
                } catch {
                    self.errorMessage = localizationManager.localizedString(for: "Error decoding recommendation.")
                }
            }
        }.resume()
    }
}

struct CropRecommendationSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    let recommendation: CropRecommendation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(localizationManager.localizedString(for: "Your Plant Recommendation"))
                    .font(.title2)
                    .foregroundColor(themeManager.currentAccentColor)
                
                ScrollView {
                    Text(recommendation.text)
                        .padding()
                }
                
                if let imageUrl = recommendation.image_url, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                    }
                    .padding()
                }
                
                Button(localizationManager.localizedString(for: "Got It")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
            }
            .padding()
            .navigationTitle(localizationManager.localizedString(for: "Recommendation"))
        }
    }
}

// MARK: - Plant Analysis Views

struct PlantAnalysisView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var apiConfig: APIConfiguration
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showActionSheet = false
    
    @State private var analysisResult: String?
    @State private var diseasesFound: String?
    @State private var remedyText: String?
    @State private var showRemedySheet = false
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.white, themeManager.currentAccentColor.opacity(0.1)]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Button(action: {
                    showActionSheet = true
                }) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    } else {
                        VStack(spacing: 18) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(themeManager.currentAccentColor)
                            Text(localizationManager.localizedString(for: "Tap to pick a plant photo"))
                                .foregroundColor(themeManager.currentAccentColor)
                                .font(.headline)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeManager.currentAccentColor, lineWidth: 2))
                        .shadow(radius: 10)
                    }
                }
                .buttonStyle(ScaledButtonStyle())
                .animation(.easeInOut, value: selectedImage)
                
                Text(localizationManager.localizedString(for: "Disease detection only supports the following plants: Strawberry, Grape, Blueberry, Corn, Peach, Pepper, Raspberry, Tomato, Cherry, Apple, Potato, Soybean"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                Spacer()
                
                if selectedImage != nil {
                    Button(localizationManager.localizedString(for: "Check My Plant")) {
                        uploadImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentAccentColor)
                    .padding(.bottom)
                }
                
                if isUploading {
                    ProgressView(localizationManager.localizedString(for: "Checking your plant..."))
                }
                
                if let analysis = analysisResult,
                   let diseases = diseasesFound {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(localizationManager.localizedString(for: "What We Found"))
                                .font(.headline)
                                .foregroundColor(themeManager.currentAccentColor)
                            Text(analysis)
                            Text(localizationManager.localizedString(for: "Possible Issues"))
                                .font(.headline)
                                .foregroundColor(themeManager.currentAccentColor)
                            Text(diseases)
                        }
                        .padding()
                    }
                    
                    if let remedy = remedyText, !remedy.isEmpty {
                        Button(localizationManager.localizedString(for: "See Fix")) {
                            showRemedySheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.currentAccentColor)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle(localizationManager.localizedString(for: "Plant Checkup"))
        .navigationBarItems(leading:
            Button {
                selectedTab = 0
            } label: {
                Label(localizationManager.localizedString(for: "Home"), systemImage: "house.fill")
                    .foregroundColor(themeManager.currentAccentColor)
            }
        )
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text(localizationManager.localizedString(for: "Photo Source")), buttons: [
                .default(Text(localizationManager.localizedString(for: "Snap a Pic"))) {
                    sourceType = .camera
                    showImagePicker = true
                },
                .default(Text(localizationManager.localizedString(for: "From Library"))) {
                    sourceType = .photoLibrary
                    showImagePicker = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showRemedySheet) {
            RemedyView(remedyText: remedyText ?? "")
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
    }
    
    func uploadImage() {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let url = URL(string: "\(apiConfig.baseURL)/plant?lang=\(localizationManager.currentLanguage)") else {
            errorMessage = localizationManager.localizedString(for: "Photo or connection issue.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"plant.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        isUploading = true
        errorMessage = nil
        analysisResult = nil
        diseasesFound = nil
        remedyText = nil
        
        URLSession.shared.uploadTask(with: request, from: body) { data, _, error in
            DispatchQueue.main.async {
                self.isUploading = false
                if let error = error {
                    self.errorMessage = localizationManager.localizedString(for: "Upload failed: ") + error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = localizationManager.localizedString(for: "No data received.")
                    return
                }
                do {
                    let responseObj = try JSONDecoder().decode(PlantAnalysisResponse.self, from: data)
                    self.analysisResult = responseObj.analysis
                    self.diseasesFound = responseObj.diseases
                    self.remedyText = responseObj.remedy
                } catch {
                    self.errorMessage = localizationManager.localizedString(for: "Error decoding analysis.")
                }
            }
        }.resume()
    }
}

struct RemedyView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    let remedyText: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(localizationManager.localizedString(for: "Your Plant Fix"))
                    .font(.title2)
                    .foregroundColor(themeManager.currentAccentColor)
                
                ScrollView {
                    Text(remedyText)
                        .padding()
                }
                
                Button(localizationManager.localizedString(for: "Got It")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentAccentColor)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .cornerRadius(10)
            .navigationTitle(localizationManager.localizedString(for: "Fix It"))
        }
    }
}

// MARK: - Main Views

struct HomepageView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var selectedTab: Int
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Enhanced animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    themeManager.currentAccentColor.opacity(0.15),
                    Color.white,
                    themeManager.currentAccentColor.opacity(0.1),
                    Color(hex: "E8F5E9").opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            .hueRotation(.degrees(isAnimating ? 8 : 0))
            .animation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true), value: isAnimating)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Welcome Section with enhanced typography
                    VStack(spacing: 15) {
                        Text(localizationManager.localizedString(for: "Hello, Gardener!"))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentAccentColor)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                            .shadow(color: themeManager.currentAccentColor.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text(localizationManager.localizedString(for: "Let's make your plants happy"))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    
                    // Features Grid with enhanced colors
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        // Grow Easy Card
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedTab = 1
                            }
                        } label: {
                            FeatureCard(
                                title: localizationManager.localizedString(for: "Grow Easy"),
                                subtitle: localizationManager.localizedString(for: "Get plant recommendations"),
                                color: Color(hex: "4CAF50"),
                                icon: "leaf.fill"
                            )
                        }
                        .buttonStyle(ScaledButtonStyle())
                        
                        // Plant Checkup Card
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedTab = 2
                            }
                        } label: {
                            FeatureCard(
                                title: localizationManager.localizedString(for: "Plant Checkup"),
                                subtitle: localizationManager.localizedString(for: "Check plant health"),
                                color: Color(hex: "2196F3"),
                                icon: "camera.fill"
                            )
                        }
                        .buttonStyle(ScaledButtonStyle())
                        
                        // Watering Plan Card
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedTab = 3
                            }
                        } label: {
                            FeatureCard(
                                title: localizationManager.localizedString(for: "Watering Plan"),
                                subtitle: localizationManager.localizedString(for: "Get daily watering CSV"),
                                color: Color(hex: "00BCD4"),
                                icon: "drop.fill"
                            )
                        }
                        .buttonStyle(ScaledButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Quick Tips Section with enhanced colors
                    VStack(alignment: .leading, spacing: 15) {
                        Text(localizationManager.localizedString(for: "Quick Tips"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentAccentColor)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                TipCard(
                                    title: localizationManager.localizedString(for: "Watering"),
                                    description: localizationManager.localizedString(for: "Check soil moisture before watering"),
                                    icon: "drop.fill",
                                    color: Color(hex: "00BCD4")
                                )
                                
                                TipCard(
                                    title: localizationManager.localizedString(for: "Sunlight"),
                                    description: localizationManager.localizedString(for: "Most plants need 6-8 hours of light"),
                                    icon: "sun.max.fill",
                                    color: Color(hex: "FF9800")
                                )
                                
                                TipCard(
                                    title: localizationManager.localizedString(for: "Temperature"),
                                    description: localizationManager.localizedString(for: "Keep plants away from drafts"),
                                    icon: "thermometer",
                                    color: Color(hex: "F44336")
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
                .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

struct TipCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(width: 160, height: 140)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct AboutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            Section(header: Label("Website", systemImage: "globe").foregroundColor(themeManager.currentAccentColor)) {
                Link("https://gardenerflask.xyz", destination: URL(string: "https://gardenerflask.xyz")!)
                    .foregroundColor(themeManager.currentAccentColor)
            }
            .listRowBackground(Color.clear)
            
            Section(header: Label("Technical Report", systemImage: "doc.text").foregroundColor(themeManager.currentAccentColor)) {
                Link(destination: URL(string: "https://github.com/michaelzhao2000/Gardener")!) {
                    HStack {
                        Text("View on GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundColor(themeManager.currentAccentColor)
                }
            }
            .listRowBackground(Color.clear)
            
            Section(header: Label("About", systemImage: "info.circle").foregroundColor(themeManager.currentAccentColor)) {
                Link(destination: URL(string: "https://github.com/mzz2345gj/PlantTools-Research/blob/main/Detailed%20Breakdown%20of%20Formulas%20for%20Plant%20Recommendation%20and%20Watering.pdf")!) {
                    HStack {
                        Text("View Technical Report")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundColor(themeManager.currentAccentColor)
                }
                
                Link(destination: URL(string: "https://gardenerflask.xyz")!) {
                    HStack {
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundColor(themeManager.currentAccentColor)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
    }
}

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var apiConfig: APIConfiguration
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let availableColors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink),
        ("cyan", .cyan),
        ("gray", .gray)
    ]
    
    var body: some View {
        Form {
            Section(header: Label(localizationManager.localizedString(for: "Look & Feel"), systemImage: "paintpalette").foregroundColor(themeManager.currentAccentColor)) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableColors, id: \.name) { colorOption in
                            Button(action: {
                                themeManager.accentColor = colorOption.name
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(colorOption.color)
                                        .frame(width: 30, height: 30)
                                    if themeManager.accentColor == colorOption.name {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .accessibilityLabel(Text(localizationManager.localizedString(for: "Select \(colorOption.name) color")))
                            .accessibilityAddTraits(themeManager.accentColor == colorOption.name ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal)
                }
                Toggle(localizationManager.localizedString(for: "Dark Mode"), isOn: $themeManager.isDarkMode)
            }
            .listRowBackground(Color.clear)
            
            Section(header: Label(localizationManager.localizedString(for: "Language"), systemImage: "globe").foregroundColor(themeManager.currentAccentColor)) {
                Picker(localizationManager.localizedString(for: "Select Language"), selection: $localizationManager.currentLanguage) {
                    Text(localizationManager.localizedString(for: "English")).tag("en")
                    Text(localizationManager.localizedString(for: "Chinese")).tag("zh")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .listRowBackground(Color.clear)
            
            Section(header: Label("About", systemImage: "info.circle").foregroundColor(themeManager.currentAccentColor)) {
                Link(destination: URL(string: "https://github.com/mzz2345gj/PlantTools-Research/blob/main/Detailed%20Breakdown%20of%20Formulas%20for%20Plant%20Recommendation%20and%20Watering.pdf")!) {
                    HStack {
                        Text("View Technical Report")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .foregroundColor(themeManager.currentAccentColor)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(localizationManager.localizedString(for: "Settings"))
    }
}

// MARK: - Watering View

struct WateringView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var apiConfig: APIConfiguration
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var locationManager = LocationManager()
    @State private var manualLat: String = ""
    @State private var manualLon: String = ""
    @State private var useCurrentLocation: Bool = true
    @State private var pots: [WateringPot] = []
    @State private var yard = WateringYard()
    @State private var wateringStart = Date()
    @State private var wateringEnd = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var apiResponse: WateringAPIResponse?
    @State private var showShareSheet = false
    @State private var csvData: Data?
    @FocusState private var focusedField: UUID?
    @Binding var selectedTab: Int

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    // Location Section
                    GroupBox(label: Label(localizationManager.localizedString(for: "Your Location"), systemImage: "location.fill").foregroundColor(themeManager.currentAccentColor)) {
                        Toggle(localizationManager.localizedString(for: "Use Current Location"), isOn: $useCurrentLocation)
                            .tint(themeManager.currentAccentColor)
                        if useCurrentLocation {
                            Button(localizationManager.localizedString(for: "Find My Location")) {
                                locationManager.fetchCurrentLocation()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(themeManager.currentAccentColor)
                            if let loc = locationManager.location {
                                Text("Lat: \(loc.coordinate.latitude, specifier: "%.4f")")
                                Text("Lon: \(loc.coordinate.longitude, specifier: "%.4f")")
                            }
                            if let error = locationManager.errorMessage {
                                Text(error).foregroundColor(.red).font(.caption)
                            }
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: 2) { // Reduced spacing from 6 to 2
                            Text(localizationManager.localizedString(for: "Manual Input")).font(.subheadline).bold()
                            HStack(spacing: 4) { // Reduced spacing
                                Text(localizationManager.localizedString(for: "Latitude") + ":").frame(width: 80, alignment: .trailing)
                                TextField(localizationManager.localizedString(for: "Example: 31.23"), text: $manualLat)
                                    .textFieldStyle(.roundedBorder)
                            }
                            HStack(spacing: 4) {
                                Text(localizationManager.localizedString(for: "Longitude") + ":").frame(width: 80, alignment: .trailing)
                                TextField(localizationManager.localizedString(for: "Example: 121.47"), text: $manualLon)
                                    .textFieldStyle(.roundedBorder)
                            }
                            Text(localizationManager.localizedString(for: "Please enter latitude and longitude.")).font(.caption).foregroundColor(.secondary)
                        }
                    }

                    // Pots Section
                    GroupBox(label: Label(localizationManager.localizedString(for: "Pots"), systemImage: "cube.box.fill").foregroundColor(themeManager.currentAccentColor)) {
                        if pots.isEmpty {
                            Text(localizationManager.localizedString(for: "Add at least one pot or leave empty if not needed.")).font(.caption).foregroundColor(.secondary)
                        }
                        ForEach($pots) { $pot in
                            VStack(alignment: .leading, spacing: 4) { // Reduced spacing from 8 to 4
                                HStack(spacing: 4) {
                                    TextField(localizationManager.localizedString(for: "Pot Name"), text: $pot.name)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: pot.id)
                                    Spacer(minLength: 8)
                                    Button(action: { pots.removeAll { $0.id == pot.id } }) {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }.accessibilityLabel(localizationManager.localizedString(for: "Delete"))
                                }
                                TextField(localizationManager.localizedString(for: "Plant Name"), text: $pot.plantName)
                                    .textFieldStyle(.roundedBorder)
                                Picker(localizationManager.localizedString(for: "Shape"), selection: $pot.shape) {
                                    Text(localizationManager.localizedString(for: "Circular")).tag("Circular")
                                    Text(localizationManager.localizedString(for: "Rectangular")).tag("Rectangular")
                                }.pickerStyle(.segmented)
                                if pot.shape == "Circular" {
                                    TextField(localizationManager.localizedString(for: "Radius (cm)"), value: $pot.radius, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    HStack(spacing: 4) {
                                        TextField(localizationManager.localizedString(for: "Length (cm)"), value: $pot.length, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                        TextField(localizationManager.localizedString(for: "Width (cm)"), value: $pot.width, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            .padding(.vertical, 4) // Reduced from 8
                            Divider()
                        }
                        Button(action: {
                            pots.append(WateringPot())
                        }) {
                            Label(localizationManager.localizedString(for: "Add Pot"), systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(themeManager.currentAccentColor)
                    }

                    // Yard Section
                    GroupBox(label: Label(localizationManager.localizedString(for: "Yard"), systemImage: "leaf.fill").foregroundColor(themeManager.currentAccentColor)) {
                        HStack(spacing: 4) {
                            Text(localizationManager.localizedString(for: "Length (m)") + ":").frame(width: 90, alignment: .trailing)
                            TextField(localizationManager.localizedString(for: "Required"), value: $yard.length, format: .number)
                                .textFieldStyle(.roundedBorder)
                            Text(localizationManager.localizedString(for: "Width (m)") + ":").frame(width: 90, alignment: .trailing)
                            TextField(localizationManager.localizedString(for: "Required"), value: $yard.width, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                        Text(localizationManager.localizedString(for: "Plants in Yard")).font(.subheadline)
                        ForEach($yard.plants) { $plant in
                            HStack(spacing: 4) {
                                TextField(localizationManager.localizedString(for: "Plant Name"), text: $plant.name)
                                    .textFieldStyle(.roundedBorder)
                                TextField(localizationManager.localizedString(for: "Area (m²)"), value: $plant.area, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                Button(action: { yard.plants.removeAll { $0.id == plant.id } }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }.accessibilityLabel(localizationManager.localizedString(for: "Delete"))
                            }
                        }
                        Button(action: {
                            yard.plants.append(WateringYardPlant())
                        }) {
                            Label(localizationManager.localizedString(for: "Add Yard Plant"), systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .tint(themeManager.currentAccentColor)
                    }

                    // Watering Period
                    GroupBox(label: Label(localizationManager.localizedString(for: "Watering Period"), systemImage: "calendar").foregroundColor(themeManager.currentAccentColor)) {
                        DatePicker(localizationManager.localizedString(for: "Start Date"), selection: $wateringStart, displayedComponents: .date)
                        DatePicker(localizationManager.localizedString(for: "End Date"), selection: $wateringEnd, in: wateringStart..., displayedComponents: .date)
                    }

                    // Submit Button
                    Button(action: submitWateringRequest) {
                        HStack {
                            if isLoading { ProgressView() }
                            Text(localizationManager.localizedString(for: "Get Watering Plan"))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentAccentColor)
                    .disabled(isLoading)

                    // Error
                    if let error = errorMessage {
                        Text(error).foregroundColor(.red).font(.caption)
                    }

                    // Result
                    if let response = apiResponse {
                        WateringResultView(response: response, onShare: shareCSV, localizationManager: localizationManager)
                    }
                }
                .padding(.horizontal)
                .padding(.top, -32) // More negative top padding to pull content even closer
            }
            .navigationTitle(localizationManager.localizedString(for: "Watering Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button {
                    selectedTab = 0
                } label: {
                    Label(localizationManager.localizedString(for: "Home"), systemImage: "house.fill")
                        .foregroundColor(themeManager.currentAccentColor)
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let csvData = csvData {
                ShareSheet(activityItems: [csvData], fileName: "watering_plan.csv")
            }
        }
    }

    func submitWateringRequest() {
        errorMessage = nil
        isLoading = true
        apiResponse = nil
        csvData = nil
        // Prepare payload
        let lat: Double?
        let lon: Double?
        if useCurrentLocation, let loc = locationManager.location {
            lat = loc.coordinate.latitude
            lon = loc.coordinate.longitude
        } else {
            lat = Double(manualLat)
            lon = Double(manualLon)
        }
        guard let latitude = lat, let longitude = lon else {
            errorMessage = localizationManager.localizedString(for: "Enter a valid location.")
            isLoading = false
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "watering_start": dateFormatter.string(from: wateringStart),
            "watering_end": dateFormatter.string(from: wateringEnd),
            "pots": pots.map { pot in
                var dict: [String: Any] = [
                    "name": pot.name,
                    "plant_name": pot.plantName,
                    "shape": pot.shape
                ]
                if pot.shape == "Circular" {
                    dict["radius"] = pot.radius ?? 0
                } else {
                    dict["length"] = pot.length ?? 0
                    dict["width"] = pot.width ?? 0
                }
                return dict
            },
            "yard": [
                "length": yard.length,
                "width": yard.width,
                "plants": yard.plants.map { ["name": $0.name, "area": $0.area] }
            ]
        ]
        guard let url = URL(string: "https://gardenerflask.xyz/api/watering") else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            errorMessage = localizationManager.localizedString(for: "Data preparation failed.")
            isLoading = false
            return
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = localizationManager.localizedString(for: "Network error: ") + error.localizedDescription
                    return
                }
                guard let data = data else {
                    errorMessage = localizationManager.localizedString(for: "No data received.")
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(WateringAPIResponse.self, from: data)
                    apiResponse = response
                    // Prepare CSV
                    csvData = makeCSVData(from: response)
                } catch {
                    errorMessage = localizationManager.localizedString(for: "Error decoding watering plan.")
                }
            }
        }.resume()
    }

    func makeCSVData(from response: WateringAPIResponse) -> Data? {
        var csv = "Date,Container,Type,Plant,Amount (L),Frequency (per week)\n"
        for day in response.dailySchedule {
            for item in day.items {
                csv += "\(day.date),\(item.container),\(item.container_type),\(item.plant),\(String(format: "%.2f", item.amount)),\(item.frequency_min)-\(item.frequency_max)\n"
            }
        }
        return csv.data(using: .utf8)
    }

    func shareCSV() {
        showShareSheet = true
    }
}

struct WateringResultView: View {
    let response: WateringAPIResponse
    var onShare: () -> Void
    var localizationManager: LocalizationManager
    
    @Environment(\.colorScheme) var colorScheme
    @State private var magnifyBy: CGFloat = 1.0
    @State private var lastMagnify: CGFloat = 1.0
    
    // Extracted CSV table rows to help type checker
    var csvTableRows: some View {
        ForEach(response.dailySchedule, id: \.date) { day in
            ForEach(day.items.enumerated().map { (idx, item) in (id: item.uniqueID(for: day.date) + "-\(idx)", item: item) }, id: \.id) { pair in
                let item = pair.item
                HStack {
                    Text(day.date).frame(width: 100, alignment: .leading)
                    Text(item.container).frame(width: 100, alignment: .leading)
                    Text(item.container_type).frame(width: 80, alignment: .leading)
                    Text(item.plant).frame(width: 120, alignment: .leading)
                    Text(String(format: "%.2f", item.amount)).frame(width: 80, alignment: .trailing)
                    Text("\(item.frequency_min)-\(item.frequency_max)").frame(width: 120, alignment: .trailing)
                }
                .font(.caption2)
                .background(colorScheme == .dark ? Color.black.opacity(0.03) : Color.white.opacity(0.7))
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(response.dailySchedule.count) " + localizationManager.localizedString(for: "days of watering recommendations ready.")).font(.headline)
            if let soil = response.soilType {
                Text(localizationManager.localizedString(for: "Soil Type") + ": " + soil)
            }
            Button(action: onShare) {
                Label(localizationManager.localizedString(for: "Download CSV"), systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .accessibilityLabel(localizationManager.localizedString(for: "Download CSV"))
            Divider()
            Text(localizationManager.localizedString(for: "CSV Preview")).font(.subheadline).bold().padding(.bottom, 2)
            Text(localizationManager.localizedString(for: "Pinch to zoom the table.")).font(.caption).foregroundColor(.secondary).padding(.bottom, 4)
            // Magnifiable CSV Table Preview
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(localizationManager.localizedString(for: "Date")).bold().frame(width: 100, alignment: .leading)
                        Text(localizationManager.localizedString(for: "Container")).bold().frame(width: 100, alignment: .leading)
                        Text(localizationManager.localizedString(for: "Type")).bold().frame(width: 80, alignment: .leading)
                        Text(localizationManager.localizedString(for: "Plant")).bold().frame(width: 120, alignment: .leading)
                        Text(localizationManager.localizedString(for: "Amount (L)")).bold().frame(width: 80, alignment: .trailing)
                        Text(localizationManager.localizedString(for: "Frequency (per week)")).bold().frame(width: 120, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.gray.opacity(0.15))
                    .accessibilityLabel(localizationManager.localizedString(for: "CSV Table Header"))
                    csvTableRows
                }
                .padding(.vertical, 4)
                .scaleEffect(magnifyBy)
                .animation(.easeInOut(duration: 0.15), value: magnifyBy)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            magnifyBy = min(max(0.7, lastMagnify * value), 3.0)
                        }
                        .onEnded { value in
                            lastMagnify = min(max(0.7, lastMagnify * value), 3.0)
                        }
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(localizationManager.localizedString(for: "CSV Table Preview"))
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
            )
            .padding(.vertical, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(localizationManager.localizedString(for: "Watering Plan Results"))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var fileName: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        if let data = activityItems.first as? Data {
            try? data.write(to: tmpURL)
            return UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        }
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Main ContentView

struct ContentView: View {
    @StateObject var themeManager = ThemeManager()
    @StateObject var apiConfig = APIConfiguration()
    @StateObject var localizationManager = LocalizationManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomepageView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label(localizationManager.localizedString(for: "Home"), systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                PlantRecommenderView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label(localizationManager.localizedString(for: "Grow"), systemImage: "leaf.fill")
            }
            .tag(1)
            
            NavigationView {
                PlantAnalysisView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label(localizationManager.localizedString(for: "Check"), systemImage: "camera.fill")
            }
            .tag(2)
            
            NavigationView {
                WateringView(selectedTab: $selectedTab)
                    .environmentObject(localizationManager)
            }
            .tabItem {
                Label(localizationManager.localizedString(for: "Watering"), systemImage: "drop.fill")
            }
            .tag(3)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label(localizationManager.localizedString(for: "Settings"), systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .accentColor(themeManager.currentAccentColor)
        .environmentObject(themeManager)
        .environmentObject(apiConfig)
        .environmentObject(localizationManager)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension WateringDayItem {
    func uniqueID(for date: String) -> String {
        "\(date)-\(container)-\(plant)"
    }
}
