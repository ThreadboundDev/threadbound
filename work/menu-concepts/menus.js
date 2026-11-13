const screen = document.querySelector("#screen");
const frame = document.querySelector("#frame");
const notice = document.querySelector("#notice");
const assets = "../../Assets/UI/";
const pages = ["Pause", "Settings", "Inventory", "Map", "Lore", "Controls", "Blossom", "Weave", "Follower", "Hot Swap", "Support", "Demo Ending"];
const gameTabs = ["Inventory", "Map", "Lore", "Controls"];
const settingTabs = ["Graphics", "Audio", "Gameplay", "Controls"];
const settings = new Map();
const equipped = ["Base Gloves", "Base Boots", "Base Head / Chest"];
const reflect = {
  Reflect: "Rest, restore health, save progress, and reset the world.",
  Weave: "Spend Thread Knots to strengthen your Threadborne.",
  Listen: "Hear the whispered memories of Eryndor.",
  Rise: "Leave the Blossom and continue your journey."
};
const stats = [["Health", "100", "115"], ["Attack", "25", "29"], ["Skill Damage", "100", "110"],
  ["Momentum Gain", "100%", "110%"], ["AP Recharge", "100%", "110%"], ["Resistance", "0%", "5%"]];
const shop = [
  ["Follower’s Knot", 12, "Pattern · +10% AP recharge and +10% momentum generation."],
  ["The World That Remembers", 5, "A Follower’s account of Eryndor. Adds an entry to Lore."],
  ["Field Note: Threadling", 2, "The Follower’s observations on Threadlings."],
  ["Field Note: Tensioner", 2, "The Follower’s observations on Tensioners."],
  ["Field Note: Loomkin", 2, "The Follower’s observations on Loomkin."]
];
let page = "Pause";
let settingTab = "Graphics";
let inventoryTab = "Equipment";
let settingsFrom = "Pause";
let categoryItem = 0;
let loreIndex = 0;
let statIndex = 0;
let shopIndex = 0;
let knots = 18;
let followerView = "Hub";
let endingView = "Main";
let controlDevice = "Keyboard & Mouse";
let quickSlot = 0;
const purchased = new Set();
const upgraded = new Set();

function button(label, action, options = {}) {
  const disabled = options.disabled ? " disabled" : "";
  const active = options.active === undefined ? "" : ' aria-pressed="' + options.active + '"';
  return '<button type="button" data-action="' + action + '"' + active + disabled + ">" + label + "</button>";
}

function tabs(items, active, action) {
  return '<nav class="tabs" aria-label="Menu tabs">' + items.map((item, i) =>
    button(item, action + ":" + i, {active: item === active})).join("") + "</nav>";
}

function row(label, value) {
  return '<div class="row"><span>' + label + "</span>" + value + "</div>";
}

function select(label, values) {
  const current = settings.get(label) ?? values[0];
  return row(label, '<select aria-label="' + label + '" data-setting="' + label + '">' +
    values.map(value => "<option" + (current === value ? " selected" : "") + ">" + value + "</option>").join("") + "</select>");
}

function slider(label, fallback) {
  const current = settings.get(label) ?? fallback;
  return row(label, '<input type="range" aria-label="' + label + '" data-setting="' + label +
    '" min="0" max="100" value="' + current + '"><output>' + current + "%</output>");
}

function settingsScreen() {
  let content;
  if (settingTab === "Graphics") {
    content = select("Resolution", ["1920 × 1080", "1600 × 900", "1280 × 720"]) +
      select("Window Mode", ["Fullscreen", "Windowed", "Borderless"]) + select("VSync", ["On", "Off"]) +
      select("Frame Rate Limit", ["60", "120", "144", "Unlimited"]) +
      select("Quality Preset", ["High", "Medium", "Low"]) + slider("Brightness", 50);
  } else if (settingTab === "Audio") {
    content = ["Master", "Music", "Background Audio", "SFX", "UI"].map(label => slider(label, 80)).join("");
  } else if (settingTab === "Gameplay") {
    content = select("Difficulty", ["Normal", "Easy", "Hard"]) +
      ["Auto Save", "Tutorial Hints", "Vibration", "Damage Numbers"].map(label => select(label, ["On", "Off"])).join("");
  } else {
    content = row("Keyboard & Mouse", button("View Bindings", "device:0")) +
      row("Controller", button("View Bindings", "device:1")) + row("Reset Bindings", button("Reset to Defaults", "reset-bindings"));
  }
  return tabs(settingTabs, settingTab, "setting") + '<section class="panel">' + content + "</section>" +
    '<div class="actions">' + button("Back", "back-settings") + "</div>";
}

const gear = [
  ["Base Gloves", "base_grapple_icon.png", 0, "Thread wraps and grapple needle."],
  ["Base Boots", "base_boots_icon.png", 1, "Standard Threadborne footwork."],
  ["Base Head / Chest", "base_chest_icon.png", 2, "The starting outfit."],
  ["Blue Gloves", "base_grapple_icon.png", 0, "Blue equipment for the gloves slot."]
];

function inventoryScreen() {
  const categories = ["All", "Key Items", "Equipment", "Materials"];
  let contents = '<p class="quiet">No items in this sample category.</p>';
  if (inventoryTab === "Equipment" || inventoryTab === "All") {
    const item = gear[categoryItem];
    contents = '<div class="inventory-slots">' + gear.map((entry, i) => button(
      '<img alt="" src="' + assets + 'Inventory/' + entry[1] + '">' + entry[0],
      "gear:" + i, {active: i === categoryItem})).join("") + '</div><h2>' + item[0] +
      '</h2><p class="description">' + item[3] + "</p>" + button("Equip", "equip");
  } else if (inventoryTab === "Materials") {
    contents = row("Thread Knots", '<output>' + knots + "</output>");
  }
  const slots = ["Gloves", "Boots", "Head / Chest", "Weapon", "Pattern"].map((label, i) =>
    row(label, "<output>" + [...equipped, "Weaver’s Shuttle", "None"][i] + "</output>")).join("");
  const statRows = stats.map(([name, value]) => row(name, "<output>" + value + "</output>")).join("");
  return '<div class="columns"><section class="panel"><h2>Threadborne</h2>' +
    '<img class="portrait" src="portrait.png" alt="Modular wooden doll wearing its starting gear">' + slots +
    '<p class="quiet">Thread Identity · Uncommitted</p></section><section class="panel">' +
    tabs(categories, inventoryTab, "category") + contents + '</section></div><details class="panel"><summary>Stats</summary>' +
    statRows + "</details>";
}

function loreScreen() {
  const entries = [["Threadbound", "World", "The opening entry is available when you begin your journey."],
    ["Blossom of Eryndor", "World", "A place to rest, reflect, and weave."],
    ["The World That Remembers", "Follower", "A Follower’s account of Eryndor."]];
  const entry = entries[loreIndex];
  return '<div class="columns"><section class="panel gear-list">' +
    entries.map((item, i) => button(item[0], "lore:" + i, {active: i === loreIndex})).join("") +
    '</section><section class="panel"><span class="accent">' + entry[1] + "</span><h2>" + entry[0] +
    "</h2><p>" + entry[2] + "</p></section></div>";
}

function controlsScreen() {
  const bindings = [["Move Left", "A", "Left Stick"], ["Move Right", "D", "Left Stick"], ["Interact", "W", "D-Pad Up"],
    ["Jump", "Space", "A"], ["Dash", "Shift", "B"], ["Grapple", "RMB", "RB"], ["Attack", "LMB", "X"], ["Pause", "Esc", "Start"]];
  return tabs(["Keyboard & Mouse", "Controller"], controlDevice, "device") +
    '<section class="panel">' + bindings.map(([label, key, pad], i) => row(label,
      button(settings.get("binding:" + controlDevice + ":" + i) ?? (controlDevice === "Controller" ? pad : key), "binding:" + i))).join("") +
    '</section><div class="actions">' + button("Reset to Defaults", "reset-bindings") + "</div>";
}

function weaveScreen() {
  const stat = stats[statIndex];
  return '<div class="columns"><section class="panel gear-list">' + stats.map((item, i) =>
    button(item[0] + " <span>" + (upgraded.has(i) ? item[2] : item[1]) + "</span>", "stat:" + i, {active: i === statIndex})).join("") +
    '</section><section class="panel"><p class="accent">Available Thread Knots · ' + knots + "</p><h2>" + stat[0] +
    "</h2>" + row("Current → Next", "<output>" + stat[1] + " → " + stat[2] + "</output>") +
    row("Cost", "<output>1 Thread Knot</output>") + '<div class="actions">' +
    button("Weave Thread", "upgrade", {disabled: knots < 1 || upgraded.has(statIndex)}) +
    button("Leave Meditation", "page:Blossom") + "</div></section></div>";
}

function followerScreen() {
  const actions = '<div class="actions">' + button("Talk", "follower:Talk") +
    button("Buy", "follower:Shop") + button("Leave", "follower:Hub") + "</div>";
  if (followerView !== "Shop") {
    return '<section class="panel compact"><img class="follower" alt="" src="../../Assets/chamber_of_first_weave/Follower/follower_wayfarers_loom.png"><p>' +
      (followerView === "Talk" ? "A curious place to meet." : "Choose Talk to listen, or Buy to see the Follower’s wares.") +
      "</p>" + actions + "</section>";
  }
  const item = shop[shopIndex];
  return '<div class="columns"><section class="panel gear-list">' + shop.map(([name, cost], i) =>
    button(name + ' <span class="cost">' + (purchased.has(i) ? "Owned" : cost + " Knots") + "</span>",
      "shop:" + i, {active: i === shopIndex})).join("") +
    '</section><section class="panel"><p class="accent">Thread Knots · ' + knots + "</p><h2>" + item[0] +
    "</h2><p>" + item[2] + '</p><div class="actions">' +
    button("Buy · " + item[1] + " Knots", "purchase", {disabled: purchased.has(shopIndex) || knots < item[1]}) +
    button("Back", "follower:Hub") + "</div></section></div>";
}

function endingScreen() {
  if (endingView !== "Main") {
    return '<section class="panel compact"><h2>' + endingView + "</h2>" +
      "<p class='quiet'>This page keeps the existing in-game content.</p>" + button("Back", "ending:Main") + "</section>";
  }
  return '<section class="panel compact"><img class="qr" alt="Playtest report QR code" src="' +
    assets + 'DemoEnding/threadbound_feedback_qr.png"><div class="actions">' +
    button("Give Playtest Feedback", "feedback") + button("A Note from Chase", "ending:A Note from Chase") +
    button("View Credits", "ending:Credits") + button("Return to Main Menu", "return-title") + "</div></section>";
}

function render() {
  document.querySelector("#screens").innerHTML = pages.map(name => button(name, "page:" + name, {active: page === name})).join("");
  frame.dataset.scene = page.toLowerCase();
  let heading = page;
  let contents = "";
  switch (page) {
    case "Pause":
      heading = "Paused";
      contents = '<div class="stack">' + button("Resume", "resume", {active:true}) +
        button("Settings", "page:Settings") + button("Playtest Support", "page:Support") + button("Quit", "quit") + "</div>";
      break;
    case "Settings": contents = settingsScreen(); break;
    case "Inventory": contents = inventoryScreen(); break;
    case "Map": contents = '<section class="panel"><h2>Chamber of the First Weave</h2><div class="map-wrap"><img class="map" src="' + assets + 'rough_map.png" alt="Existing Chamber map"><span class="map-marker" title="Current position" aria-label="Sample player position"></span></div></section>'; break;
    case "Lore": contents = loreScreen(); break;
    case "Controls": contents = controlsScreen(); break;
    case "Blossom":
      heading = "The Blossom Awaits";
      contents = '<div class="compact"><div class="stack">' + Object.keys(reflect).map((name, i) =>
        button(name, "blossom:" + name, {active:i === 0})).join("") +
        '</div><p class="description">' + reflect.Reflect + "</p></div>";
      break;
    case "Weave": heading = "Meditation"; contents = weaveScreen(); break;
    case "Follower": heading = "The Follower"; contents = followerScreen(); break;
    case "Hot Swap":
      heading = "Select Grapple";
      contents = '<section class="panel compact"><div class="quick-select">' + ["Monarch", "Sage", "Hermit"].map((name, i) =>
        button(name, "quick:" + i, {active:i === quickSlot})).join("") +
        '</div><p class="hint">Hold to open · Aim to select · Release to equip</p></section>';
      break;
    case "Support":
      heading = "Playtest Support";
      contents = '<section class="panel compact"><p>Share broader thoughts in the playtest report, or send a focused bug report.</p><div class="stack">' +
        button("Fill Out Playtest Report", "feedback") + button("Report a Bug", "bug") + button("Back", "page:Pause") + "</div></section>";
      break;
    case "Demo Ending": heading = "Thank You for Playing"; contents = endingScreen(); break;
  }
  const nav = gameTabs.includes(page) ? tabs(gameTabs, page, "game") : "";
  screen.innerHTML = "<h1>" + heading + "</h1>" + nav + contents;
}

function showPage(name) {
  if (name === "Settings" && page !== "Settings") settingsFrom = page;
  page = name;
  notice.textContent = "";
  render();
}

document.addEventListener("click", event => {
  const target = event.target.closest("button[data-action]");
  if (!target) return;
  const [action, value] = target.dataset.action.split(":");
  const index = Number(value);
  notice.textContent = "";
  switch (action) {
    case "page": showPage(value); return;
    case "game": showPage(gameTabs[index]); return;
    case "setting": settingTab = settingTabs[index]; break;
    case "back-settings": showPage(settingsFrom); return;
    case "category": inventoryTab = ["All", "Key Items", "Equipment", "Materials"][index]; break;
    case "gear": categoryItem = index; break;
    case "equip": equipped[gear[categoryItem][2]] = gear[categoryItem][0]; break;
    case "lore": loreIndex = index; break;
    case "device":
      controlDevice = index === 0 ? "Keyboard & Mouse" : "Controller";
      if (page === "Settings") { showPage("Controls"); return; }
      break;
    case "binding":
      notice.textContent = "Press a key to preview a binding.";
      window.addEventListener("keydown", key => {
        if (key.key !== "Escape") settings.set("binding:" + controlDevice + ":" + index, key.key === " " ? "Space" : key.key);
        notice.textContent = "";
        render();
      }, {once:true});
      return;
    case "reset-bindings":
      for (const key of settings.keys()) if (key.startsWith("binding:")) settings.delete(key);
      notice.textContent = "Sample bindings restored.";
      break;
    case "blossom":
      if (value === "Weave") { showPage("Weave"); return; }
      screen.querySelector(".description").textContent = reflect[value];
      screen.querySelectorAll(".stack button").forEach(node => node.setAttribute("aria-pressed", String(node === target)));
      return;
    case "stat": statIndex = index; break;
    case "upgrade": knots -= 1; upgraded.add(statIndex); break;
    case "follower": followerView = value; break;
    case "shop": shopIndex = index; break;
    case "purchase": knots -= shop[shopIndex][1]; purchased.add(shopIndex); break;
    case "quick": quickSlot = index; break;
    case "ending": endingView = value; break;
    default:
      notice.textContent = {
        resume: "Resume returns to gameplay.", quit: "Quit closes the game.",
        feedback: "Opens the existing playtest report.", bug: "Opens the existing bug report.",
        "return-title": "Returns to the startup title screen."
      }[action];
      return;
  }
  render();
  const equivalent = [...document.querySelectorAll("button[data-action]")].find(node => node.dataset.action === target.dataset.action);
  if (equivalent && !equivalent.disabled) equivalent.focus({preventScroll:true});
});

document.addEventListener("input", event => {
  const control = event.target;
  if (!control.dataset.setting) return;
  settings.set(control.dataset.setting, control.value);
  if (control.type === "range") control.nextElementSibling.value = control.value + "%";
});
document.querySelector("#accent").addEventListener("change", event => {
  document.documentElement.dataset.accent = event.target.value;
});
render();
