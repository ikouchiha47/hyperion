
#include <cstdio>
#include <qlogging.h>
#include "thieflite.h"

#define TFLITE_MINIMAL_CHECK(x, msg)                              \
  if (!(x)) {                                                \
    qDebug() << msg << "Error at " << __FILE__ << ":" << __LINE__;  \
    return false;                                            \
  }

TFLiteModel* TFLiteModel::instancePtr = nullptr;

TFLiteModel::TFLiteModel(QObject* parent): QObject(parent) {
  static int counter = 0;
    qDebug() << "TFLiteModel instance created" << ++counter;
}

TFLiteModel* TFLiteModel::instance() {
  if(instancePtr == nullptr) {
    qDebug() << "recreating instance ptr";

    instancePtr = new TFLiteModel();
  }

  return instancePtr;
}

bool TFLiteModel::loadModel(const QString& modelPath) {
  qDebug() << "Loading model";;

  std::unique_ptr<tflite::FlatBufferModel> modelPtr =
    tflite::FlatBufferModel::BuildFromFile(modelPath.toStdString().c_str());

  TFLITE_MINIMAL_CHECK(modelPtr != nullptr, "failed to load model");

  model = std::move(modelPtr);

  if (model == nullptr) {
        emit modelLoadingFailed();
        return false;
    }

  TFLITE_MINIMAL_CHECK(model != nullptr, "failed to move model");

  tflite::ops::builtin::BuiltinOpResolver resolver;
  tflite::InterpreterBuilder builder(*model, resolver);  
  
  builder(&interpreter);

  TFLITE_MINIMAL_CHECK(interpreter != nullptr, "failed to load interpreter");

  TFLITE_MINIMAL_CHECK(interpreter->AllocateTensors() == kTfLiteOk, "failed to load tensors");

  qDebug() << "successfully loaded model and tensors";

  m_isModelLoaded = true;
  emit modelLoadedChanged();

  return true;
}

bool TFLiteModel::isMalicious(const QString& input) {
  TFLITE_MINIMAL_CHECK(interpreter != nullptr, "model not loaded.");

  qDebug() << "checking is malicious";

  float res = runInference(input);
  qDebug() << "Probability of malicious" << res;

  return res > 0.4;
}

float TFLiteModel::runInference(const QString& input) {
  TFLITE_MINIMAL_CHECK(interpreter != nullptr, "model not loaded")

  qDebug() << "model loaded check, getting tensor";

  // Get input tensor
  const TfLiteTensor* inputTensorMeta = interpreter->tensor(0);
  TFLITE_MINIMAL_CHECK(inputTensorMeta != nullptr, "Error: Input tensor is not initialized!");

  // Get the input tensor and assign the value
  float* inputTensor = interpreter->typed_input_tensor<float>(0);
  TFLITE_MINIMAL_CHECK(inputTensor != nullptr, "Error: Failed to get the input tensor.");

  // Assuming a single float input
  inputTensor[0] = input.toFloat();

  qDebug() << "Tensor set, running inference";

  // Run inference
  TFLITE_MINIMAL_CHECK(interpreter->Invoke() == kTfLiteOk, "Failed to run inference!");

  // Get the output tensor and return the result
  float* outputTensor = interpreter->typed_output_tensor<float>(0);
  TFLITE_MINIMAL_CHECK(outputTensor != nullptr, "Error: Output tensor is not initialized");

  qDebug() << "Inference complete, returning output";
  return outputTensor[0];
}
