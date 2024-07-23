package com.example.myapp;
import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.easycap";
    private static final int REQUEST_CODE_PERMISSIONS = 1;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("startStreaming")) {
                                if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) 
                                        != PackageManager.PERMISSION_GRANTED) {
                                    ActivityCompat.requestPermissions(this, 
                                        new String[]{Manifest.permission.CAMERA}, REQUEST_CODE_PERMISSIONS);
                                } else {
                                    startStreaming();
                                    result.success("Streaming started");
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void startStreaming() {
        UsbManager usbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
        UsbDevice device = getEasyCapDevice(usbManager);
        if (device != null) {
            UsbDeviceConnection connection = connectDevice(usbManager, device);
            if (connection != null) {
                configureVideoCapture(connection);
            }
        }
    }

    private UsbDevice getEasyCapDevice(UsbManager usbManager) {
        for (UsbDevice device : usbManager.getDeviceList().values()) {
            if (device.getVendorId() == 0x534d && device.getProductId() == 0x0021) {
                return device;
            }
        }
        return null;
    }

    private UsbDeviceConnection connectDevice(UsbManager usbManager, UsbDevice device) {
        UsbDeviceConnection connection = usbManager.openDevice(device);
        if (connection != null) {
            connection.claimInterface(device.getInterface(0), true);
        }
        return connection;
    }

    private void configureVideoCapture(UsbDeviceConnection connection) {
        // Implement video capture configuration here
        // Example: sending control transfer commands to the device
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startStreaming();
            }
        }
    }
}
