# Inventory Cleanup Assistant

The addon reviews sellable items in your carried bags. The window has three lists:

- **Review** contains Common through Epic items that are not marked for sale or kept safe.
- **Sell** contains items selected for sale. Poor-quality items are selected by default.
- **Ignore** contains items explicitly excluded from sale.
- Items with "Hearthstone" in their name are hidden from every list and cannot be selected for sale.
- Use **Show 0-value** to include items with no vendor value in the lists. The setting is saved and defaults to on.

Each item row shows the value of one item and the total value of its stack, with the price spaced after a clipped item name. Click **Sell**, **Ignore**, or **Review** on an item to move it between lists. Saved Sell and Ignore rules remain visible when those items are not in your bags and can still be removed or changed. Window positions are saved. There is no auto-sell switch: all eligible items in **Sell** are sold automatically when a vendor opens. Use `/ica` to show or hide the window.

Open Settings and select **Join Discord** for community support. The invite dialog lets you copy the link with Ctrl+C.

When entering an instance, a separate **Farm Loot** window opens and tracks bag item gains for the current session. Its persistent **Farm Loot** setting in Settings defaults to enabled; disabling it stops automatic tracking, auto-sell, and instance popups while preserving the temporary list. It waits for the bag contents to settle before setting the initial baseline, so pre-existing items are not added while the inventory loads. Tracking pauses outside instances, but the list, remaining loot counts, and farm auto-sell toggle stay active for the next merchant visit; bag snapshots refresh after zone transitions settle. If the window was open, it reopens after a loading screen. Merchant sales update the tracked remaining quantity and remove fully sold entries from the window. The unique-item list is temporary and clears on reload, but remains when you change instances. Use `/ica farm` or the **Farm Loot** button to reopen it. **Clear** empties the temporary list and resets the baseline to the items currently in your bags. Farm auto-sell is off by default and is not saved; reagent selling is off by default and saved. With reagent selling off, reagents show zero potential value and are skipped by farm auto-sell. Farm auto-sell only sells complete stacks that fit within the tracked loot quantity, to protect identical items you already had. When reagent selling is enabled, **Split** becomes available at a merchant if a mixed reagent stack must be separated; click it to split the tracked amount into a free general bag slot, then auto-sell resumes. **Clone to Sell** adds the tracked item IDs to the main sale list without creating duplicates. Farm Loot window position is saved.

The addon ignores quest, locked, lootable, and no-value items, along with Legendary, Artifact, and Heirloom quality items. Equippable items in your bags can appear in Review. It scans carried bags only, not the bank or equipped gear. Vendor sales are permanent.

Lua modules are grouped by domain under `core/` and `ui/`. Shared UI builders create themed frames, buttons, and item rows for both the inventory and Farm Loot lists. Farm tracking, stack handling, farm item data, and Farm Loot presentation are separate modules; Farm Loot rows are virtualized so large sessions reuse a bounded number of row frames.
