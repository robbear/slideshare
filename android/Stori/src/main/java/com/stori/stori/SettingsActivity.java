package com.stori.stori;

import android.app.ActionBar;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.stori.stori.cloudproviders.AmazonSharedPreferencesWrapper;
import com.stori.stori.cloudproviders.GoogleLogin;

import static com.stori.stori.Config.D;
import static com.stori.stori.Config.E;

public class SettingsActivity extends Activity {
    public final static String TAG = "SettingsActivity";

    public final static String EXTRA_LAUNCHFROMEDIT = "extra_launchfromedit";

    public final static int REQUEST_GOOGLE_LOGIN_FROM_SWITCHACCOUNT_SETTINGS = 1;
    public final static int RESULT_CODE_SWITCHACCOUNT_FAILED = RESULT_FIRST_USER + 1;

    private SharedPreferences m_prefs;
    private LinearLayout m_autoPlayPanel;
    private CheckBox m_autoPlayCB;
    private RelativeLayout m_aboutPanel;
    private TextView m_buildStringText;
    private RelativeLayout m_switchAccountPanel;
    private TextView m_currentAccountText;
    private boolean m_isLaunchedFromEdit = false;

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if(D) Log.d(TAG, "SettingsActivity.onOptionsItemSelected");

        switch (item.getItemId()) {
            case android.R.id.home:
                if(D)Log.d(TAG, "SettingsActivity.onOptionsItemSelected: up button clicked. Finishing activity.");
                finish();
                return true;
        }

        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        if(D)Log.d(TAG, "SettingsActivity.onCreate");

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        m_prefs = getSharedPreferences(SSPreferences.PREFS(this), Context.MODE_PRIVATE);

        m_isLaunchedFromEdit = getIntent().getBooleanExtra(EXTRA_LAUNCHFROMEDIT, false);

        ActionBar actionBar = getActionBar();
        actionBar.setTitle(getString(R.string.settings_actionbar));
        actionBar.setDisplayHomeAsUpEnabled(true);

        m_autoPlayCB = (CheckBox)findViewById(R.id.settings_autoaudio_checkbox);
        m_autoPlayCB.setChecked(m_prefs.getBoolean(SSPreferences.PREFS_PLAYSLIDESAUTOAUDIO(this), SSPreferences.DEFAULT_PLAYSLIDESAUTOAUDIO(this)));
        m_autoPlayCB.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                SharedPreferences.Editor edit = m_prefs.edit();
                edit.putBoolean(SSPreferences.PREFS_PLAYSLIDESAUTOAUDIO(SettingsActivity.this), isChecked);
                edit.commit();
            }
        });

        // Allow tapping on full line
        m_autoPlayPanel = (LinearLayout)findViewById(R.id.settings_autoplay_panel);
        m_autoPlayPanel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                m_autoPlayCB.toggle();
            }
        });

        m_buildStringText = (TextView)findViewById(R.id.settings_buildstring_text);
        m_buildStringText.setText(String.format(getString(R.string.settings_buildstring_format), Config.buildString));

        m_aboutPanel = (RelativeLayout)findViewById(R.id.settings_about_panel);
        m_aboutPanel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(SettingsActivity.this, AboutActivity.class);
                startActivity(intent);
            }
        });

        String email = AmazonSharedPreferencesWrapper.getUserEmail(m_prefs);
        m_currentAccountText = (TextView)findViewById(R.id.settings_current_account_text);
        m_currentAccountText.setText(String.format(getString(R.string.settings_currentaccount_format), email));

        m_switchAccountPanel = (RelativeLayout)findViewById(R.id.settings_account_panel);
        m_switchAccountPanel.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                switchAccount();
            }
        });

        if (!m_isLaunchedFromEdit) {
            m_switchAccountPanel.setVisibility(View.GONE);
            RelativeLayout sep = (RelativeLayout)findViewById(R.id.settings_account_panel_separator);
            sep.setVisibility(View.GONE);
        }
    }

    @Override
    public void onDestroy() {
        if(D)Log.d(TAG, "SettingsActivity.onDestroy");

        super.onDestroy();
    }

    @Override
    public void onStart() {
        if(D)Log.d(TAG, "SettingsActivity.onStart");

        super.onStart();
    }

    @Override
    public void onStop() {
        if(D)Log.d(TAG, "SettingsActivity.onStop");

        super.onStop();
    }

    @Override
    public void onResume() {
        if(D)Log.d(TAG, "SettingsActivity.onResume");

        super.onResume();
    }

    @Override
    public void onPause() {
        if(D)Log.d(TAG, "SettingsActivity.onPause");

        super.onPause();
    }

    @Override
    public void onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        if(D)Log.d(TAG, String.format("SettingsActivity.onActivityResult: requestCode=%d, resultCode=%d", requestCode, resultCode));

        if (requestCode == REQUEST_GOOGLE_LOGIN_FROM_SWITCHACCOUNT_SETTINGS) {
            if (resultCode == RESULT_OK) {
                if(D)Log.d(TAG, "SettingsActivity.onActivityResult - handling REQUEST_GOOGLE_LOGIN_FROM_SWITCHACCOUNT_SETTINGS");
                setResult(RESULT_OK);
                finish();
                return;
            }
        }
        else {
            if(D)Log.d(TAG, "SettingsActivity.onActivityResult - something bad happened in Switch Account. Returning RESULT_CANCEL");
            setResult(RESULT_CODE_SWITCHACCOUNT_FAILED);
            finish();
            return;
        }
    }

    private void switchAccount() {
        if(D)Log.d(TAG, "SettingsActivity.switchAccount");

        AlertDialog.Builder adb = new AlertDialog.Builder(this);
        adb.setTitle(getString(R.string.switch_account_dialog_title));
        adb.setCancelable(true);
        adb.setMessage(getString(R.string.switch_account_dialog_message));
        adb.setPositiveButton(getString(R.string.yes_text), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if(D)Log.d(TAG, "EditPlayActivity.switchAccount - switching account");
                dialog.dismiss();

                Intent intent = new Intent(SettingsActivity.this, GoogleLogin.class);
                intent.putExtra(GoogleLogin.EXTRA_FORCE_ACCOUNT_PICKER, true);
                startActivityForResult(intent, REQUEST_GOOGLE_LOGIN_FROM_SWITCHACCOUNT_SETTINGS);
            }
        });
        adb.setNegativeButton(getString(R.string.no_text), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });

        AlertDialog ad = adb.create();
        ad.show();
    }
}
