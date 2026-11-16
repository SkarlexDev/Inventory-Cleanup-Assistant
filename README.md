# Inventory Cleanup Assistant

The addon reviews sellable items in your carried bags. The window has three lists:

- **Review** contains Common through Epic items that are not marked for sale or kept safe.
- **Sell** contains items selected for sale. Poor-quality items are selected by default.
- **Ignore** contains items explicitly excluded from sale.
- Items with "Hearthstone" in their name are hidden from every list and cannot be selected for sale.
- Use **Show 0-value** to include items with no vendor value in the lists. The setting is saved and defaults to on.

Each item row shows the value of one item and the total value of its stack, with the price spaced after a clipped item name. Click **Sell**, **Ignore**, or **Review** on an item to move it between lists. Saved Sell and Ignore rules remain visible when those items are not in your bags and can still be removed or changed. Window positions are saved. There is no auto-sell switch: all eligible items in **Sell** are sold automatically when a vendor opens. Use `/ica` to show or hide the window.

Open Settings and select **Join Discord** for community support. The invite dialog lets you copy the link with Ctrl+C.

The addon ignores quest, locked, lootable, and no-value items, along with Legendary, Artifact, and Heirloom quality items. Equippable items in your bags can appear in Review. It scans carried bags only, not the bank or equipped gear. Vendor sales are permanent.

Lua modules are grouped by domain under `core/` and `ui/`. Shared UI builders create themed frames, buttons, and item rows for the inventory list.
