const CampaignMapSelect = {
    onLoad() {
        const container = $('#SettingPageInsert');

        const chapters = [
            {
                title: "Chapter 1",
                maps: [
                    "sp_a1_intro1",
                    "sp_a1_intro2",
                    "sp_a1_intro3"
                ]
            },
            {
                title: "Chapter 2",
                maps: [
                    "sp_a2_laser_intro",
                    "sp_a2_laser_stairs",
                    "sp_a2_dual_lasers"
                ]
            }
        ];

        for (const chapter of chapters) {
            const header = $.CreatePanel('Label', container, '');
            header.text = chapter.title;
            header.AddClass('campaign-maps__chapter-title');

            for (const map of chapter.maps) {
                const entry = $.CreatePanel('RadioButton', container, '');
                entry.BLoadLayoutSnippet('MapEntrySnippet');
                entry.FindChildTraverse('Title').text = map;

                entry.SetPanelEvent('onactivate', () => {
                    GameInterfaceAPI.ConsoleCommand(`map ${map}`);
                });
            }
        }
    }
};
