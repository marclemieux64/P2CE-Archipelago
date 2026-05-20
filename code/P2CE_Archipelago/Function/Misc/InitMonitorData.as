namespace Archipelago {

void InitMonitorData() {
            // Sécurité : on ne remplit le dictionnaire que s'il est vide
            if (!screen_names.isEmpty()) return;

            dictionary sp_a4_tb_intro; sp_a4_tb_intro.set("monitor1-relay_break", "sp_a4_tb_intro");
            screen_names.set("sp_a4_tb_intro", sp_a4_tb_intro);

            dictionary sp_a4_tb_trust_drop; sp_a4_tb_trust_drop.set("monitor1-relay_break", "sp_a4_tb_trust_drop");
            screen_names.set("sp_a4_tb_trust_drop", sp_a4_tb_trust_drop);

            dictionary sp_a4_tb_wall_button; sp_a4_tb_wall_button.set("wheatley_monitor-relay_break", "sp_a4_tb_wall_button");
            screen_names.set("sp_a4_tb_wall_button", sp_a4_tb_wall_button);

            dictionary sp_a4_tb_polarity; sp_a4_tb_polarity.set("monitor1-relay_break", "sp_a4_tb_polarity");
            screen_names.set("sp_a4_tb_polarity", sp_a4_tb_polarity);

            dictionary sp_a4_tb_catch; 
            sp_a4_tb_catch.set("monitor1-relay_break", "sp_a4_tb_catch 1");
            sp_a4_tb_catch.set("monitor2-relay_break", "sp_a4_tb_catch 2");
            screen_names.set("sp_a4_tb_catch", sp_a4_tb_catch);

            dictionary sp_a4_stop_the_box; sp_a4_stop_the_box.set("wheatley_monitor-relay_break", "sp_a4_stop_the_box");
            screen_names.set("sp_a4_stop_the_box", sp_a4_stop_the_box);

            dictionary sp_a4_laser_catapult; sp_a4_laser_catapult.set("wheatley_monitor_1-relay_break", "sp_a4_laser_catapult");
            screen_names.set("sp_a4_laser_catapult", sp_a4_laser_catapult);

            dictionary sp_a4_laser_platform; sp_a4_laser_platform.set("wheatley_monitor_1-relay_break", "sp_a4_laser_platform");
            screen_names.set("sp_a4_laser_platform", sp_a4_laser_platform);

            dictionary sp_a4_speed_tb_catch; sp_a4_speed_tb_catch.set("wheatley_monitor-relay_break", "sp_a4_speed_tb_catch");
            screen_names.set("sp_a4_speed_tb_catch", sp_a4_speed_tb_catch);

            dictionary sp_a4_jump_polarity; sp_a4_jump_polarity.set("wheatley_monitor_1-relay_break", "sp_a4_jump_polarity");
            screen_names.set("sp_a4_jump_polarity", sp_a4_jump_polarity);

            dictionary sp_a4_finale3; sp_a4_finale3.set("wheatley_screen-relay_break", "sp_a4_finale3");
            screen_names.set("sp_a4_finale3", sp_a4_finale3);
        }

} // namespace Archipelago
