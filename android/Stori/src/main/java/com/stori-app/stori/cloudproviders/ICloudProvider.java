package com.stori-app.stori.cloudproviders;

import android.content.SharedPreferences;

import java.util.HashMap;

public interface ICloudProvider {
    public void initializeProvider(String containerName, SharedPreferences prefs) throws Exception;
    public void deleteVirtualDirectory(String directoryName) throws Exception;
    public void uploadFile(String folder, String fileName, String contentType) throws Exception;
}
