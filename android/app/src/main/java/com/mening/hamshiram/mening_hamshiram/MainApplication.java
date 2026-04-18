package com.mening.hamshiram.mening_hamshiram;

import android.app.Application;
import com.yandex.mapkit.MapKitFactory;

public class MainApplication extends Application {
  @Override
  public void onCreate() {
    super.onCreate();
    MapKitFactory.setApiKey("98449d46-f8a5-423b-a1a7-fc89c4e1d0d9");
  }
}
