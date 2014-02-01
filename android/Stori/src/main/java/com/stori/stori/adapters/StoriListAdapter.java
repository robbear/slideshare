package com.stori.stori.adapters;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.PopupMenu;
import android.widget.TextView;

import com.stori.stori.R;
import com.stori.stori.StoriListItem;

import org.w3c.dom.Text;

import java.util.ArrayList;

import static com.stori.stori.Config.D;
import static com.stori.stori.Config.E;

public class StoriListAdapter extends BaseAdapter {
    public final static String TAG = "StoriListAdapter";

    private Context m_context;
    private LayoutInflater m_inflater;
    private ArrayList<StoriListItem> m_storiListItems;

    public StoriListAdapter(Context context) {
        if(D)Log.d(TAG, "StoriListAdapter constructor");

        m_context = context;
        m_inflater = (LayoutInflater)context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
    }

    public void setStoriListItems(ArrayList<StoriListItem> items) {
        if(D)Log.d(TAG, "StoriListAdapter.setStoriListItems");

        m_storiListItems = items;
    }

    @Override
    public int getCount() {
        if (m_storiListItems != null) {
            return m_storiListItems.size();
        }
        else {
            return 0;
        }
    }

    @Override
    public Object getItem(int position) {
        if (m_storiListItems != null && position < m_storiListItems.size()) {
            return m_storiListItems.get(position);
        }
        else {
            return null;
        }
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        if (convertView == null) {
            convertView = m_inflater.inflate(R.layout.item_storiitem, parent, false);
        }

        final StoriListItem sli = (StoriListItem)getItem(position);
        if (sli == null) {
            if(D)Log.d(TAG, "StoriListAdapter.getView - got null for child item, so bailing");
            return null;
        }

        TextView titleView = (TextView)convertView.findViewById(R.id.text_title);
        titleView.setText(sli.getTitle());

        TextView dateView = (TextView)convertView.findViewById(R.id.text_date);
        dateView.setText(sli.getModifiedDate());

        int count = sli.getSlideCount();
        TextView countView = (TextView)convertView.findViewById(R.id.text_count);
        countView.setText(count == 1 ?
                m_context.getString(R.string.storilistadapter_count_text_single) :
                String.format(m_context.getString(R.string.storilistadapter_count_text_format, count)));

        convertView.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                if(D)Log.d(TAG, "StoriListAdapter.onLongClick");

                PopupMenu pm = new PopupMenu(m_context, view);
                pm.inflate(R.menu.menu_storilistitem);
                Menu menu = pm.getMenu();

                MenuItem play = menu.findItem(R.id.menu_storilistitem_play);
                play.setTitle(String.format(m_context.getString(R.string.menu_storilistitem_play_format), sli.getTitle()));
                play.setOnMenuItemClickListener(new MenuItem.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {

                        return true;
                    }
                });

                MenuItem edit = menu.findItem(R.id.menu_storilistitem_edit);
                edit.setTitle(String.format(m_context.getString(R.string.menu_storilistitem_edit_format), sli.getTitle()));
                edit.setOnMenuItemClickListener(new MenuItem.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        return true;
                    }
                });

                MenuItem share = menu.findItem(R.id.menu_storilistitem_share);
                share.setTitle(String.format(m_context.getString(R.string.menu_storilistitem_share_format), sli.getTitle()));
                share.setOnMenuItemClickListener(new MenuItem.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        return true;
                    }
                });

                MenuItem delete = menu.findItem(R.id.menu_storilistitem_delete);
                delete.setTitle(String.format(m_context.getString(R.string.menu_storilistitem_delete_format), sli.getTitle()));
                delete.setOnMenuItemClickListener(new MenuItem.OnMenuItemClickListener() {
                    @Override
                    public boolean onMenuItemClick(MenuItem item) {
                        return true;
                    }
                });

                pm.show();

                return true;
            }
        });

        return convertView;
    }
}
