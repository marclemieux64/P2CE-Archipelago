// =============================================================
// ARCHIPELAGO LEGACY TEXT QUEUE
// =============================================================

class TextQueue {
    int font_size;
    float pos_x;
    float pos_y;
    float display_time;
    string default_color;

    array<string> text_queue;
    array<string> color_queue;

    TextQueue(float x = 0.025f, float y = 0.05f, int size = 0, float time = 4.0f, string def_color = "250 232 182") {
        this.font_size = size;
        this.pos_x = x;
        this.pos_y = y;
        this.display_time = time;
        this.default_color = def_color;
    }

    void AddToQueue(string text, string color = "") {
        this.text_queue.insertLast(text);
        if (color != "") {
            this.color_queue.insertLast(color);
        } else {
            this.color_queue.insertLast(this.default_color);
        }
    }

    void DisplayQueueMessage() {
        if (this.text_queue.length() == 0) {
            return;
        }

        string text = this.text_queue[0];
        this.text_queue.removeAt(0);
        string color = this.color_queue[0];
        this.color_queue.removeAt(0);

        // Convert the Squirrel ppmod.text call to a native game_text entity
        CBaseEntity@ gt = util::CreateEntityByName("game_text");
        if (gt !is null) {
            // Setup visual properties
            gt.KeyValue("message", text);
            gt.KeyValue("x", "" + this.pos_x);
            gt.KeyValue("y", "" + this.pos_y);
            gt.KeyValue("color", color);
            gt.KeyValue("holdtime", "" + this.display_time);
            gt.KeyValue("fadin", "0.1");
            gt.KeyValue("fadout", "0.1");
            gt.KeyValue("spawnflags", "1"); // Display to all players
            
            gt.Spawn();
            
            // Trigger the display
            Variant vNone;
            gt.FireInput("Display", vNone, 0.0f, null, null, 0);
            
            // Self-destruct after the message is finished
            gt.Remove(); 
            // Note: In Source, game_text only needs to exist to fire the 'Display' event 
            // to the client's HUD. The HUD then manages the rendering.
        }
    }
}
