package com.stori.stori;

import android.content.Context;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.MalformedURLException;
import java.util.ArrayList;

import static com.stori.stori.Config.D;
import static com.stori.stori.Config.E;

//
// SlideShareJSON example:
//
//  {
//      title: "Title text",
//      description: "Description text",
//      version: 1,
//      transitionEffect: 0,
//      slides: {
//          guidval1: { image: "http://foo.com/1.jpg", audio: "http://foo.com/1.3gp", text: "user text" },
//          guidval2: { image: "http://foo.com/2.jpg", audio: "http://foo.com/2.3gp", text: "user text" },
//          guidval3: { image: "http://foo.com/3.jpg", audio: "http://foo.com/3.3gp", text: "user text" }
//      },
//      order: [ guidval2, guidval3, guidval1 ]
//  }
//

public class SlideShareJSON extends JSONObject {
    public final static String TAG = "SlideShareJSON";

    public final static String KEY_TITLE = "title";
    public final static String KEY_DESCRIPTION = "description";
    public final static String KEY_VERSION = "version";
    public final static String KEY_TRANSITIONEFFECT = "transitionEffect";
    public final static String KEY_SLIDES = "slides";
    public final static String KEY_IMAGE = "image";
    public final static String KEY_AUDIO = "audio";
    public final static String KEY_TEXT = "text";
    public final static String KEY_ORDER = "order";

    private Context m_context;

    public enum TransitionEffects {
        None;
    };
    // Cache TransitionEffects.values() for doing enum-to-int conversions
    public TransitionEffects[] TransitionEffectsValues = TransitionEffects.values();

    public SlideShareJSON(Context context) throws JSONException {
        if(D)Log.d(TAG, "SlideShareJSON.SlideShareJSON");

        m_context = context;

        put(KEY_TITLE, m_context.getString(R.string.default_stori_title));
        put(KEY_DESCRIPTION, m_context.getString(R.string.default_stori_description));
        put(KEY_VERSION, 1);
        put(KEY_TRANSITIONEFFECT, TransitionEffects.None.ordinal());

        JSONObject slides = new JSONObject();
        put(KEY_SLIDES, slides);

        JSONArray orderArray = new JSONArray();
        put(KEY_ORDER, orderArray);

        if(D)Log.d(TAG, String.format("SlideShareJSON: initial JSON = %s", this.toString()));
    }

    public SlideShareJSON(Context context, String json) throws JSONException {
        super(json);

        m_context = context;

        if(D)Log.d(TAG, String.format("SlideShareJSON.SlideShareJSON constructed from string: %s", json));
    }

    public void setTitle(String title) throws JSONException {
        put(KEY_TITLE, title);
    }

    public String getTitle() throws JSONException {
        return getString(KEY_TITLE);
    }

    public void setDescription(String description) throws JSONException {
        put(KEY_DESCRIPTION, description);
    }

    public String getDescription() throws JSONException {
        return getString(KEY_DESCRIPTION);
    }

    public void setVersion(int version) throws JSONException {
        put(KEY_VERSION, version);
    }

    public int getVersion() throws JSONException {
        return getInt(KEY_VERSION);
    }

    public boolean isPublished() throws JSONException {
        int version = getVersion();

        return (version > 1);
    }

    public void setTransitionEffect(TransitionEffects effect) throws JSONException {
        put(KEY_TRANSITIONEFFECT, effect.ordinal());
    }

    public TransitionEffects getTransitionEffect() throws JSONException {
        int effectOrdinal = getInt(KEY_TRANSITIONEFFECT);

        return TransitionEffectsValues[effectOrdinal];
    }

    public JSONObject getSlides() throws JSONException {
        return getJSONObject(KEY_SLIDES);
    }

    public void setSlides(JSONObject slides) throws JSONException {
        put(KEY_SLIDES, slides);
    }

    public JSONArray getOrder() throws JSONException {
        return getJSONArray(KEY_ORDER);
    }

    public void setOrder(JSONArray order) throws JSONException {
        put(KEY_ORDER, order);
    }

    public void upsertSlide(String uuidString, int index, SlideJSON slide) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.upsertSlide: uuid=%s, slide=%s", uuidString, slide.toString()));

        String imageUrl = slide.getImageUrlString();
        String audioUrl = slide.getAudioUrlString();
        String slideText = slide.getText();

        upsertSlide(uuidString, index, imageUrl, audioUrl, slideText, false);
    }

    public void reorder(int currentPosition, int newPosition) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.reorder: currentPosition=%d, newPosition=%d", currentPosition, newPosition));

        JSONArray orderArray = getOrder();
        int count = orderArray.length();

        if ((currentPosition >= count) || (currentPosition < 0) || (newPosition >= count) || (newPosition < 0)) {
            if(D)Log.d(TAG, String.format("SlideShareJSON.reorder: invalid arguments. count=%d", count));
            throw new IllegalArgumentException("Invalid arguments results in out of range");
        }

        String uuid = (String)orderArray.get(currentPosition);

        // First, remove the item by building a new ArrayList
        ArrayList<String> arrayList = new ArrayList<String>();
        for (int i = 0; i < count; i++) {
            String item = orderArray.getString(i);
            if (!uuid.equalsIgnoreCase(item)) {
                arrayList.add(item);
            }
        }

        // Next, insert the saved item in the right position
        arrayList.add(newPosition, uuid);

        // Finally, convert to a JSONArray
        JSONArray newOrderArray = new JSONArray(arrayList);
        setOrder(newOrderArray);
    }

    public void upsertSlide(String uuidString, int index, String imageUrl, String audioUrl, String slideText, boolean forceNulls) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.upsertSlide: uuid=%s, index=%d, imageUrl=%s, audioUrl=%s, slideText=%s, forceNulls=%b", uuidString, index, imageUrl, audioUrl, slideText, forceNulls));

        JSONObject slides = getSlides();
        JSONObject slide = null;

        if (slides.has(uuidString)) {
            slide = slides.getJSONObject(uuidString);
        }

        if (slide != null) {
            if(D)Log.d(TAG, String.format("SlideShareJSON.upsertSlide - found slide and updating for uuid=%s", uuidString));

            if (forceNulls || (imageUrl != null)) {
                slide.put(KEY_IMAGE, imageUrl);
            }

            if (forceNulls || (audioUrl != null)) {
                slide.put(KEY_AUDIO, audioUrl);
            }

            if (forceNulls || (slideText != null)) {
                slide.put(KEY_TEXT, slideText);
            }
        }
        else {
            if(D)Log.d(TAG, String.format("SlideShareJSON.upsertSlide - no slide found for %s, so creating new slide", uuidString));

            JSONArray orderArray = getOrder();

            JSONObject paths = new JSONObject();
            paths.put(KEY_IMAGE, imageUrl);
            paths.put(KEY_AUDIO, audioUrl);
            paths.put(KEY_TEXT, slideText);

            int oldCount = orderArray.length();
            slides.put(uuidString, paths);
            if (index < 0 || index >= oldCount) {
                // Put the new item at the end
                orderArray.put(uuidString);
            }
            else {
                // Rebuild orderArray by inserting the new item
                JSONArray newOrderArray = new JSONArray();

                for (int i = 0; i < oldCount; i++) {
                    if (i == index) {
                        newOrderArray.put(uuidString);
                    }
                    newOrderArray.put(orderArray.getString(i));
                }

                setOrder(newOrderArray);
            }
        }
    }

    public void removeSlide(String uuidString) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.removeSlide: uuid=%s", uuidString));

        JSONObject slides = getSlides();
        JSONObject slide = null;

        if (slides.has(uuidString)) {
            if(D)Log.d(TAG, "SlideShareJSON.removeSlide - removing slide and order entry");

            JSONArray orderArray = getOrder();
            JSONArray newOrderArray = new JSONArray();

            // Remove the item from the "order" array by rebuilding the array
            // without the item.
            for (int i = 0; i < orderArray.length(); i++) {
                String item = orderArray.getString(i);
                if (!uuidString.equalsIgnoreCase(item)) {
                    newOrderArray.put(item);
                }
            }

            setOrder(newOrderArray);
            slides.remove(uuidString);
        }
        else {
            if(D)Log.d(TAG, "SlideShareJSON.removeSlide - no slide found. Bailing");
        }
    }

    public SlideJSON getSlide(int index) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getSlide(%d)", index));

        String uuid = getSlideUuidByOrderIndex(index);
        return getSlide(uuid);
    }

    public SlideJSON getSlide(String uuidSlide) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getSlide: uuid=%s", uuidSlide));

        JSONObject slides = getSlides();

        if (slides.has(uuidSlide)) {
            return new SlideJSON(slides.getJSONObject(uuidSlide));
        }
        else {
            return null;
        }
    }

    public int getOrderIndex(String uuidSlide) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getOrderIndex for %s", uuidSlide));

        JSONArray order = getOrder();

        for (int i = 0; i < order.length(); i++) {
            if (uuidSlide.equalsIgnoreCase((String)order.get(i))) {
                if(D)Log.d(TAG, String.format("SlideShareJSON.getOrderIndex returning %d", i));
                return i;
            }
        }

        if(D)Log.d(TAG, "SlideShareJSON.getOrderIndex - no slide found");
        return -1;
    }

    public int getSlideCount() throws JSONException {
        int count = getOrder().length();

        //if(D)Log.d(TAG, String.format("SlideShareJSON.getSlideCount returns %d", count));

        return count;
    }

    public String getSlideUuidByOrderIndex(int index) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getSlideUuidByOrderIndex: index=%d", index));

        int count = getSlideCount();

        if (index < 0 || index > count - 1) {
            return null;
        }

        return getOrder().getString(index);
    }

    public String getNextSlideUuid(String uuidSlide) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getNextSlideUuid: uuid=%s", uuidSlide));

        int index = getOrderIndex(uuidSlide);
        if (index < 0) {
            return null;
        }

        int count = getSlideCount();

        if (index == count - 1) {
            return null;
        }
        else {
            return getOrder().getString(index + 1);
        }
    }

    public String[] getImageFileNames() throws JSONException, MalformedURLException {
        if(D)Log.d(TAG, "SlideShareJSON.getImageFileNames");

        ArrayList<String> imageFileNames = new ArrayList<String>();
        SlideJSON sj;

        int count = getSlideCount();
        for (int i = 0; i < count; i++) {
            sj = getSlide(i);
            String fileName = sj.getImageFilename();
            if (fileName != null) {
                imageFileNames.add(fileName);
            }
        }

        return imageFileNames.toArray(new String[imageFileNames.size()]);
    }

    public String[] getAudioFileNames() throws JSONException, MalformedURLException {
        if(D)Log.d(TAG, "SlideShareJSON.getAudioFileNames");

        ArrayList<String> audioFileNames = new ArrayList<String>();
        SlideJSON sj;

        int count = getSlideCount();
        for (int i = 0; i < count; i++) {
            sj = getSlide(i);
            String fileName = sj.getAudioFilename();
            if (fileName != null) {
                audioFileNames.add(fileName);
            }
        }

        return audioFileNames.toArray(new String[audioFileNames.size()]);
    }

    public String getPreviousSlideUuid(String uuidSlide) throws JSONException {
        if(D)Log.d(TAG, String.format("SlideShareJSON.getPreviousSlideUuid: uuid=%s", uuidSlide));

        int index = getOrderIndex(uuidSlide);
        if (index <= 0) {
            return null;
        }

        return getOrder().getString(index - 1);
    }

    public boolean save(Context context, String folder, String fileName) {
        if(D)Log.d(TAG, String.format("SlideShareJSON.save: folder=%s, fileName=%s", folder, fileName));

        return Utilities.saveStringToFile(context, this.toString(), folder, fileName);
    }

    public static SlideShareJSON load(Context context, String folder, String fileName) {
        if(D)Log.d(TAG, String.format("SlideShareJSON.load: folder=%s, fileName=%s", folder, fileName));

        SlideShareJSON ssj = null;
        String json = Utilities.loadStringFromFile(context, folder, fileName);

        if (json == null) {
            return null;
        }

        //if(D)Log.d(TAG, "****** " + json);

        try {
            ssj = new SlideShareJSON(context, json);
        }
        catch (Exception e) {
            if(E)Log.e(TAG, "SlideShareJSON.load", e);
            e.printStackTrace();
        }
        catch (OutOfMemoryError e) {
            if(E)Log.e(TAG, "SlideShareJSON.load", e);
            e.printStackTrace();
        }

        return ssj;
    }

    public static String getSlideShareTitle(Context context, String folder) {
        if(D)Log.d(TAG, "SlideShareJSON.getSlideShareTitle");

        SlideShareJSON ssj = load(context, folder, Config.slideShareJSONFilename);
        if (ssj == null) {
            return null;
        }

        String title = null;

        try {
            title = ssj.getTitle();
        }
        catch (Exception e) {
            if(E)Log.e(TAG, "SlideShareJSON.getSlideShareTitle", e);
            e.printStackTrace();
        }
        catch (OutOfMemoryError e) {
            if(E)Log.e(TAG, "SlideShareJSON.getSlideShareTitle", e);
            e.printStackTrace();
        }

        return title;
    }

    public static boolean isSlideSharePublished(Context context, String folder) {
        if(D)Log.d(TAG, "SlideShareJSON.isSlideSharePublished");

        SlideShareJSON ssj = load(context, folder, Config.slideShareJSONFilename);
        if (ssj == null) {
            return false;
        }

        boolean isPublished = false;

        try {
            isPublished = ssj.isPublished();
        }
        catch (Exception e) {
            if(E)Log.e(TAG, "SlideShareJSON.isSlideSharePublished", e);
            e.printStackTrace();
        }
        catch (OutOfMemoryError e) {
            if(E)Log.e(TAG, "SlideShareJSON.isSlideSharePublished", e);
            e.printStackTrace();
        }

        return isPublished;
    }
}
