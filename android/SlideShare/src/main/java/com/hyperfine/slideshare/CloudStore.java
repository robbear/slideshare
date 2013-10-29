package com.hyperfine.slideshare;

import android.content.Context;
import android.os.AsyncTask;
import android.util.Log;

import com.hyperfine.slideshare.cloudproviders.ICloudProvider;
import com.hyperfine.slideshare.cloudproviders.WindowsAzureProvider;

import java.util.HashMap;
import java.util.concurrent.RejectedExecutionException;

import static com.hyperfine.slideshare.Config.D;
import static com.hyperfine.slideshare.Config.E;

public class CloudStore {
    public final static String TAG = "CloudStore";

    Config.CloudStorageProviders m_cloudProvider;
    Context m_context;
    String m_slideShareName;
    String m_userUuid;
    ICloudStoreCallback m_callback;
    SlideShareJSON m_ssj;
    boolean m_saveInProgress = false;

    public interface ICloudStoreCallback {
        public void onSaveComplete(SaveErrors err);
    }

    public enum SaveErrors {
        None,
        Error_LoadJSON,
        Error_UploadFile,
        Error_OutOfMemory,
        Error_Unknown
    };
    public SaveErrors[] SaveErrorsValues = SaveErrors.values();

    protected class SaveTask extends AsyncTask<Object, Void, SaveErrors> {

        @Override
        protected SaveErrors doInBackground(Object... params) {
            if(D)Log.d(TAG, "CloudStore.SaveTask.doInBackground");

            SaveErrors se = SaveErrors.None;

            try {
                String[] imageFileNames = m_ssj.getImageFileNames();
                String[] audioFileNames = m_ssj.getAudioFileNames();

                ICloudProvider icp;

                switch (Config.CLOUD_STORAGE_PROVIDER) {
                    default:
                    case Azure:
                        icp = new WindowsAzureProvider(m_context);
                        break;

                    case AWS:
                        icp = null;
                        break;
                }

                icp.initializeProvider(m_userUuid);
                icp.deleteVirtualDirectory(m_slideShareName);

                HashMap<String, String> metaDataImage = new HashMap<String, String>();
                HashMap<String, String> metaDataAudio = new HashMap<String, String>();
                HashMap<String, String> metaDataJSON = new HashMap<String, String>();

                metaDataImage.put("Content-Type", "image/jpeg");
                metaDataAudio.put("Content-Type", "audio/3gpp");
                metaDataJSON.put("Content-Type", "application/json");

                for (String fileName : imageFileNames) {
                    icp.uploadFile(m_slideShareName, fileName, metaDataImage);
                }
                for (String fileName : audioFileNames) {
                    icp.uploadFile(m_slideShareName, fileName, metaDataAudio);
                }

                icp.uploadFile(m_slideShareName, Config.slideShareJSONFilename, metaDataJSON);
            }
            catch (Exception e) {
                if(E)Log.e(TAG, "CloudStore.SaveTask.doInBackground", e);
                e.printStackTrace();

                se = SaveErrors.Error_UploadFile;
            }
            catch (OutOfMemoryError e) {
                if(E)Log.e(TAG, "CloudStore.SaveTask.doInBackground", e);
                e.printStackTrace();

                se = SaveErrors.Error_OutOfMemory;
            }

            return se;
        }

        @Override
        protected void onPostExecute(SaveErrors saveErrors) {
            if(D)Log.d(TAG, String.format("CloudStore.SaveTask.onPostExecute: %s", saveErrors));

            m_callback.onSaveComplete(saveErrors);
        }
    }

    public CloudStore(Context context, String userUuid, String slideShareName, Config.CloudStorageProviders cloudProvider, ICloudStoreCallback callback) {
        if(D)Log.d(TAG, String.format("CloudStore.CloudStore: userUuid=%s, slideShareName=%s, cloudProvider=%s", userUuid, slideShareName, cloudProvider));

        m_context = context;
        m_userUuid = userUuid;
        m_slideShareName = slideShareName;
        m_cloudProvider = cloudProvider;
        m_callback = callback;
    }

    public void saveAsync() {
        if(D)Log.d(TAG, "CloudStore.save");

        m_ssj = SlideShareJSON.load(m_context, m_slideShareName, Config.slideShareJSONFilename);
        if (m_ssj == null) {
            m_callback.onSaveComplete(SaveErrors.Error_LoadJSON);
            return;
        }

        try {
            new SaveTask().executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
        }
        catch (RejectedExecutionException e) {
            if(E)Log.e(TAG, "CloudStore.saveAsync", e);
            e.printStackTrace();
        }
        catch (Exception e) {
            if(E)Log.e(TAG, "CloudStore.saveAsync", e);
            e.printStackTrace();
        }
        catch (OutOfMemoryError e) {
            if(E)Log.e(TAG, "CloudStore.saveAsync", e);
            e.printStackTrace();
        }
    }
}
