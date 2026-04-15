#include <Arduino.h>
#include <Wire.h>
#include <math.h>

// ===== BLE =====
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ===== TensorFlow Lite =====
#include "model_data.h"

#include <TensorFlowLite_ESP32.h>
#include <tensorflow/lite/micro/all_ops_resolver.h>
#include <tensorflow/lite/micro/micro_interpreter.h>
#include <tensorflow/lite/micro/micro_error_reporter.h>
#include <tensorflow/lite/schema/schema_generated.h>

// ===== Sensor Setup =====
#define MPU_ADDR 0x68
#define MQ9_PIN 34

// ===== Calibration =====
float accOffset[3] = {0,0,0};
float gyroOffset[3] = {0,0,0};
const int CALIBRATION_SAMPLES = 100;

// ===== MQ9 Constants =====
const float RL = 10000.0;
const float VCC = 5.0;
float R0 = 12772.99;

const float A_CO = 99.042;
const float B_CO = -1.518;

// ===== Features =====
const int FEATURES = 7;
float raw_features[FEATURES];

// ===== CNN Buffer =====
const int TIMESTEPS = 10;
float input_buffer[TIMESTEPS][FEATURES];
int buffer_index = 0;

// ===== TensorFlow Lite Setup =====
constexpr int tensorArenaSize = 16 * 1024;
uint8_t tensorArena[tensorArenaSize];

tflite::MicroInterpreter* interpreter = nullptr;
TfLiteTensor* input = nullptr;
TfLiteTensor* output = nullptr;

tflite::MicroErrorReporter micro_error_reporter;
tflite::ErrorReporter* error_reporter = &micro_error_reporter;

// ===== BLE Definitions =====
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// ===== BLE Callbacks =====
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("📲 BLE Connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("📴 BLE Disconnected");
    BLEDevice::startAdvertising();
  }
};

// ===== I2C Helpers =====
void i2cWrite(uint8_t reg, uint8_t data) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(data);
  Wire.endTransmission(true);
}

void i2cReadData(uint8_t reg, uint8_t* buf, uint8_t len) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MPU_ADDR, (size_t)len, true);

  for (int i=0; i<len && Wire.available(); i++)
    buf[i] = Wire.read();
}

// ===== Read MPU =====
void readMPU(float &ax, float &ay, float &az,
             float &gx, float &gy, float &gz) {

  uint8_t buf[14];
  i2cReadData(0x3B, buf, 14);

  int16_t rawAx = (buf[0]<<8) | buf[1];
  int16_t rawAy = (buf[2]<<8) | buf[3];
  int16_t rawAz = (buf[4]<<8) | buf[5];
  int16_t rawGx = (buf[8]<<8) | buf[9];
  int16_t rawGy = (buf[10]<<8) | buf[11];
  int16_t rawGz = (buf[12]<<8) | buf[13];

  ax = rawAx / 16384.0;
  ay = rawAy / 16384.0;
  az = rawAz / 16384.0;

  gx = rawGx / 131.0;
  gy = rawGy / 131.0;
  gz = rawGz / 131.0;
}

// ===== Calibrate MPU =====
void calibrateMPU() {
  Serial.println("🔧 Calibrating MPU...");
  float accSum[3] = {0,0,0};
  float gyroSum[3] = {0,0,0};

  float ax, ay, az, gx, gy, gz;

  for (int i=0; i<CALIBRATION_SAMPLES; i++) {
    readMPU(ax, ay, az, gx, gy, gz);
    accSum[0]+=ax;
    accSum[1]+=ay;
    accSum[2]+=az;
    gyroSum[0]+=gx;
    gyroSum[1]+=gy;
    gyroSum[2]+=gz;
    delay(50);
  }

  for (int i=0;i<3;i++) {
    accOffset[i]=accSum[i]/CALIBRATION_SAMPLES;
    gyroOffset[i]=gyroSum[i]/CALIBRATION_SAMPLES;
  }

  Serial.println("✅ MPU Calibrated");
}

// ===== MQ9 Conversion =====
float getMQ9PPM(int adcValue) {
  float Vout = (adcValue / 4095.0) * 3.3;
  if (Vout <= 0.01) return 0;

  float Rs = RL * (VCC - Vout) / Vout;
  float ratio = Rs / R0;

  float ppm = pow(10, (log10(ratio) - log10(A_CO)) / B_CO);
  return ppm;
}

// ===== BLE Setup =====
void setupBLE() {

  BLEDevice::init("SmokeBand");

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_NOTIFY
  );

  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEDevice::startAdvertising();

  Serial.println("📡 BLE Ready");
}

// ===== Setup =====
void setup() {

  Serial.begin(115200);
  Wire.begin(21,22);

  i2cWrite(0x6B, 0x00);
  delay(100);

  calibrateMPU();
  analogSetPinAttenuation(MQ9_PIN, ADC_11db);

  // ===== CNN Init =====
  const tflite::Model* model =
      tflite::GetModel(smokeband_cnn_quantized_tflite);

  static tflite::AllOpsResolver resolver;

  static tflite::MicroInterpreter static_interpreter(
      model,
      resolver,
      tensorArena,
      tensorArenaSize,
      error_reporter
  );

  interpreter = &static_interpreter;

  interpreter->AllocateTensors();

  input = interpreter->input(0);
  output = interpreter->output(0);

  Serial.println("✅ CNN Model Loaded");

  setupBLE();
}

// ===== Loop =====
void loop() {

  float ax, ay, az, gx, gy, gz;

  readMPU(ax, ay, az, gx, gy, gz);

  float mqPPM = getMQ9PPM(analogRead(MQ9_PIN));

  raw_features[0]=ax-accOffset[0];
  raw_features[1]=ay-accOffset[1];
  raw_features[2]=az-accOffset[2];
  raw_features[3]=gx-gyroOffset[0];
  raw_features[4]=gy-gyroOffset[1];
  raw_features[5]=gz-gyroOffset[2];
  raw_features[6]=mqPPM;

  memcpy(input_buffer[buffer_index], raw_features, sizeof(raw_features));
  buffer_index++;

  if (buffer_index == TIMESTEPS) {

    memcpy(input->data.f, input_buffer, sizeof(input_buffer));

    if (interpreter->Invoke() == kTfLiteOk) {

      float probability = output->data.f[0];
      int prediction = (probability > 0.5);

      // ===== Combined JSON =====
      String jsonData="{";

      jsonData += "\"accX\":"+String(raw_features[0],3);
      jsonData += ",\"accY\":"+String(raw_features[1],3);
      jsonData += ",\"accZ\":"+String(raw_features[2],3);

      jsonData += ",\"gyroX\":"+String(raw_features[3],3);
      jsonData += ",\"gyroY\":"+String(raw_features[4],3);
      jsonData += ",\"gyroZ\":"+String(raw_features[5],3);

      jsonData += ",\"mq9_ppm\":"+String(raw_features[6],2);
      jsonData += ",\"prediction\":"+String(prediction);

      jsonData += "}";

      Serial.println(jsonData);

      if (deviceConnected) {
        pCharacteristic->setValue(jsonData.c_str());
        pCharacteristic->notify();
      }
    }

    buffer_index = 0;
  }

  delay(1000);
}
