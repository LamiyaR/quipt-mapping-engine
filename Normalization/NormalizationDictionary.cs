namespace QuiptMappingEngine.Normalization;

public static class NormalizationDictionary
{
    // Normalizes variant terms to a canonical form so both sides can match.
    public static readonly Dictionary<string, string> Map = new(StringComparer.OrdinalIgnoreCase)
    {
        // ═══════════════════════════════════════════════════════
        // Display / Screen
        // ═══════════════════════════════════════════════════════
        ["screen"] = "display",
        ["display"] = "display",
        ["monitor"] = "display",
        ["scrn"] = "display",
        ["scrnsize"] = "screensize",
        ["dsply"] = "display",
        ["bezel"] = "bezel",
        ["thickness"] = "thickness",
        ["brightness"] = "brightness",
        ["surface"] = "surface",
        ["refresh"] = "refresh",
        ["rate"] = "rate",
        ["rfrsh"] = "refreshrate",
        ["native"] = "native",
        ["resolution"] = "resolution",
        ["maxres"] = "resolution",
        ["nativeres"] = "nativeresolution",
        ["touch"] = "touch",
        ["dispglass"] = "displayglass",

        // ═══════════════════════════════════════════════════════
        // Color
        // ═══════════════════════════════════════════════════════
        ["colour"] = "color",
        ["color"] = "color",
        ["exactcolor"] = "color",
        ["genericcolor"] = "color",

        // ═══════════════════════════════════════════════════════
        // Memory / RAM
        // ═══════════════════════════════════════════════════════
        ["ram"] = "memory",
        ["memory"] = "memory",
        ["ramsize"] = "memory",
        ["ramtype"] = "memorytype",
        ["rammax"] = "memorymax",
        ["ramslot"] = "memoryslot",

        // ═══════════════════════════════════════════════════════
        // Hard disk / Storage
        // ═══════════════════════════════════════════════════════
        ["hdd"] = "harddisk",
        ["harddisk"] = "harddisk",
        ["hard"] = "harddisk",
        ["hdtype"] = "harddisk",
        ["hdtypehware"] = "harddisk",
        ["hdsize"] = "storage",
        ["hdspeed"] = "harddiskspeed",

        // Storage / SSD / Flash / Capacity
        ["ssd"] = "storage",
        ["storage"] = "storage",
        ["solid"] = "storage",
        ["flash"] = "storage",
        ["digital"] = "digital",
        ["capacity"] = "size",
        ["installed"] = "installed",
        ["rotational"] = "speed",

        // ═══════════════════════════════════════════════════════
        // Brand / Manufacturer
        // ═══════════════════════════════════════════════════════
        ["manufacturer"] = "brand",
        ["maker"] = "brand",
        ["brand"] = "brand",
        ["brandname"] = "brand",

        // ═══════════════════════════════════════════════════════
        // Model
        // ═══════════════════════════════════════════════════════
        ["modelnbr"] = "model",
        ["model"] = "model",

        // ═══════════════════════════════════════════════════════
        // Processor / CPU
        // ═══════════════════════════════════════════════════════
        ["cpu"] = "processor",
        ["processor"] = "processor",
        ["proc"] = "processor",
        ["cpucore"] = "processorcore",
        ["cpunum"] = "processor",
        ["cpuspeed"] = "processorspeed",
        ["cpuseries"] = "processorseries",
        ["cpucache"] = "processorcache",
        ["numprocessor"] = "processorcount",
        ["cores"] = "core",
        ["core"] = "core",
        ["count"] = "count",
        ["cache"] = "cache",

        // ═══════════════════════════════════════════════════════
        // GPU / Graphics
        // ═══════════════════════════════════════════════════════
        ["gpu"] = "graphics",
        ["graphics"] = "graphics",
        ["gputype"] = "graphics",
        ["gpumodel"] = "graphicsmodel",
        ["gpusize"] = "graphicssize",
        ["gpuramtype"] = "graphicsmemorytype",
        ["video"] = "graphics",
        ["coprocessor"] = "graphics",
        ["card"] = "card",
        ["interface"] = "interface",

        // ═══════════════════════════════════════════════════════
        // Operating System
        // ═══════════════════════════════════════════════════════
        ["os"] = "operatingsystem",
        ["operatingsystem"] = "operatingsystem",
        ["desktopos"] = "operatingsystem",
        ["tabos"] = "operatingsystem",

        // ═══════════════════════════════════════════════════════
        // Weight
        // ═══════════════════════════════════════════════════════
        ["wt"] = "weight",
        ["weight"] = "weight",
        ["itemweight"] = "weight",
        ["lbs"] = "weight",
        ["pounds"] = "weight",

        // ═══════════════════════════════════════════════════════
        // Dimensions
        // ═══════════════════════════════════════════════════════
        ["dim"] = "dimension",
        ["dimensions"] = "dimension",
        ["dimension"] = "dimension",
        ["itemdims"] = "dimension",
        ["length"] = "length",
        ["width"] = "width",
        ["height"] = "height",
        ["depth"] = "depth",

        // ═══════════════════════════════════════════════════════
        // Description
        // ═══════════════════════════════════════════════════════
        ["desc"] = "description",
        ["description"] = "description",

        // ═══════════════════════════════════════════════════════
        // Name / Title / Item
        // ═══════════════════════════════════════════════════════
        ["title"] = "name",
        ["name"] = "name",
        ["item"] = "item",

        // ═══════════════════════════════════════════════════════
        // Wireless / Connectivity / Bluetooth
        // ═══════════════════════════════════════════════════════
        ["wifi"] = "wireless",
        ["wireless"] = "wireless",
        ["bluetooth"] = "bluetooth",
        ["bt"] = "bluetooth",
        ["bluetoothver"] = "bluetooth",
        ["bluspd"] = "bluetooth",
        ["connectivity"] = "connectivity",
        ["lancompat"] = "ethernet",
        ["technology"] = "technology",
        ["comm"] = "communication",
        ["communication"] = "communication",
        ["standard"] = "standard",
        ["wirelesstech"] = "wirelesstechnology",
        ["cellularnetwork"] = "cellularnetwork",

        // ═══════════════════════════════════════════════════════
        // Battery
        // ═══════════════════════════════════════════════════════
        ["battery"] = "battery",
        ["batt"] = "battery",
        ["bat"] = "battery",
        ["batlife"] = "batterylife",
        ["battype"] = "batterytype",
        ["batcap"] = "batterycapacity",
        ["batweight"] = "batteryweight",
        ["batsize"] = "batterysize",
        ["lithium"] = "lithium",
        ["cell"] = "cell",
        ["cells"] = "cell",
        ["composition"] = "composition",

        // ═══════════════════════════════════════════════════════
        // Camera
        // ═══════════════════════════════════════════════════════
        ["camera"] = "camera",
        ["cam"] = "camera",
        ["webcam"] = "camera",
        ["rearcam"] = "rearcamera",
        ["frontcam"] = "frontcamera",
        ["still"] = "still",
        ["effective"] = "effective",
        ["megapixel"] = "megapixel",
        ["camres"] = "cameraresolution",
        ["numwebcam"] = "cameracount",
        ["webcamtype"] = "cameratype",

        // ═══════════════════════════════════════════════════════
        // Image
        // ═══════════════════════════════════════════════════════
        ["image"] = "image",
        ["img"] = "image",
        ["photo"] = "image",

        // ═══════════════════════════════════════════════════════
        // Price / MSRP
        // ═══════════════════════════════════════════════════════
        ["msrp"] = "price",
        ["price"] = "price",

        // ═══════════════════════════════════════════════════════
        // SKU / UPC / Identifier
        // ═══════════════════════════════════════════════════════
        ["sku"] = "sku",
        ["upc"] = "upc",
        ["ean"] = "ean",

        // ═══════════════════════════════════════════════════════
        // Country
        // ═══════════════════════════════════════════════════════
        ["country"] = "country",
        ["origin"] = "origin",

        // ═══════════════════════════════════════════════════════
        // Warranty
        // ═══════════════════════════════════════════════════════
        ["warranty"] = "warranty",

        // ═══════════════════════════════════════════════════════
        // Condition
        // ═══════════════════════════════════════════════════════
        ["condition"] = "condition",
        ["cond"] = "condition",

        // ═══════════════════════════════════════════════════════
        // Lifestyle / Uses / Product
        // ═══════════════════════════════════════════════════════
        ["pclifestyle"] = "lifestyle",
        ["lifestyle"] = "lifestyle",
        ["uses"] = "uses",
        ["specific"] = "specific",
        ["product"] = "product",
        ["recommended"] = "recommended",
        ["purpose"] = "uses",

        // ═══════════════════════════════════════════════════════
        // USB / Ports / Connectors
        // ═══════════════════════════════════════════════════════
        ["usbprt"] = "usb2ports",
        ["usbpwr"] = "usb3ports",
        ["usbcports"] = "usbcports",
        ["usbprtfrt"] = "usbfrontports",
        ["usb"] = "usb",
        ["port"] = "port",
        ["ports"] = "port",
        ["connector"] = "connector",
        ["jack"] = "jack",
        ["thunderbolt"] = "thunderbolt",
        ["ethernet"] = "ethernet",
        ["lanport"] = "ethernetport",

        // ═══════════════════════════════════════════════════════
        // HDMI / Display ports / Video out
        // ═══════════════════════════════════════════════════════
        ["hdmi"] = "hdmi",
        ["totaldvi"] = "dvi",
        ["totaldslprt"] = "displayport",
        ["maxdisplsup"] = "maxdisplay",
        ["dvi"] = "dvi",
        ["vga"] = "vga",

        // ═══════════════════════════════════════════════════════
        // Optical drive
        // ═══════════════════════════════════════════════════════
        ["optdr1"] = "opticaldrive",
        ["optical"] = "optical",
        ["dvdspd"] = "dvdspeed",

        // ═══════════════════════════════════════════════════════
        // Form factor
        // ═══════════════════════════════════════════════════════
        ["desktopformfact"] = "formfactor",
        ["notebookformfact"] = "formfactor",
        ["formfactor"] = "formfactor",
        ["formfact"] = "formfactor",
        ["convertible"] = "formfactor",
        ["detachable"] = "formfactor",

        // ═══════════════════════════════════════════════════════
        // Keyboard / Mouse
        // ═══════════════════════════════════════════════════════
        ["keyboardincl"] = "keyboard",
        ["keyboardcon"] = "keyboard",
        ["keyboardlang"] = "keyboardlanguage",
        ["keytype"] = "keyboardtype",
        ["litkey"] = "backlightkeyboard",
        ["touchbar"] = "touchbar",
        ["mouseincl"] = "mouse",
        ["mousecon"] = "mouse",

        // ═══════════════════════════════════════════════════════
        // Audio
        // ═══════════════════════════════════════════════════════
        ["hdphnjack"] = "headphone",
        ["micphnjack"] = "microphone",
        ["mic"] = "microphone",
        ["bltinspkrs"] = "speaker",
        ["speaker"] = "speaker",

        // ═══════════════════════════════════════════════════════
        // Energy
        // ═══════════════════════════════════════════════════════
        ["energystar"] = "energystar",
        ["epeatlvl"] = "epeat",

        // ═══════════════════════════════════════════════════════
        // Release / Year / Date
        // ═══════════════════════════════════════════════════════
        ["releasedate"] = "releasedate",
        ["releaseyear"] = "releaseyear",
        ["release"] = "release",
        ["year"] = "year",
        ["date"] = "date",
        ["merchant"] = "merchant",

        // ═══════════════════════════════════════════════════════
        // Plug type
        // ═══════════════════════════════════════════════════════
        ["plugtype"] = "plugtype",

        // ═══════════════════════════════════════════════════════
        // Product generation / line
        // ═══════════════════════════════════════════════════════
        ["prodgen"] = "generation",
        ["desktopprodline"] = "productline",
        ["notebookprodline"] = "productline",
        ["phoneprodline"] = "productline",
        ["generation"] = "generation",

        // ═══════════════════════════════════════════════════════
        // Media
        // ═══════════════════════════════════════════════════════
        ["mediacardreader"] = "cardreader",

        // ═══════════════════════════════════════════════════════
        // Cooling
        // ═══════════════════════════════════════════════════════
        ["liquidcool"] = "cooling",

        // ═══════════════════════════════════════════════════════
        // PCI slots
        // ═══════════════════════════════════════════════════════
        ["totalpcix1"] = "pcislot",
        ["totalpcix8"] = "pcislot",
        ["totalpcix16"] = "pcislot",
        ["availpcix1"] = "pcislot",
        ["availpcix8"] = "pcislot",
        ["availpcix16"] = "pcislot",

        // ═══════════════════════════════════════════════════════
        // Expansion bays
        // ═══════════════════════════════════════════════════════
        ["totalexpbay"] = "expansionbay",
        ["total35extbay"] = "expansionbay",
        ["total35intbay"] = "expansionbay",
        ["total525extbay"] = "expansionbay",
        ["totalhotswap"] = "hotswap",

        // ═══════════════════════════════════════════════════════
        // Special / Misc
        // ═══════════════════════════════════════════════════════
        ["specialnote"] = "note",
        ["bundsoft"] = "software",
        ["optanemem"] = "optane",
        ["milspec"] = "milspec",
        ["fingerrdr"] = "fingerprint",

        // ═══════════════════════════════════════════════════════
        // Smartphone-specific
        // ═══════════════════════════════════════════════════════
        ["scrnsiz"] = "screensize",
        ["scrnres"] = "resolution",
        ["simtype"] = "sim",
        ["dualsim"] = "dualsim",
        ["nfc"] = "nfc",
        ["gps"] = "gps",
        ["accelerometer"] = "sensor",
        ["gyroscope"] = "sensor",
        ["celltech"] = "cellulartechnology",
        ["storsize"] = "storage",
        ["networkprovider"] = "networkprovider",

        // ═══════════════════════════════════════════════════════
        // Numeric / General modifiers
        // ═══════════════════════════════════════════════════════
        ["total"] = "total",
        ["number"] = "number",
        ["num"] = "number",
        ["quantity"] = "count",
        ["maximum"] = "maximum",
        ["max"] = "maximum",
        ["minimum"] = "minimum",
        ["min"] = "minimum",
        ["size"] = "size",
        ["type"] = "type",

        // ═══════════════════════════════════════════════════════
        // Remaining compound fragments (for compound code splitter)
        // ═══════════════════════════════════════════════════════
        ["hware"] = "hardware",
        ["nbr"] = "number",
        ["spd"] = "speed",
        ["ver"] = "version",
        ["compat"] = "compatibility",
        ["incl"] = "included",
        ["con"] = "connection",
        ["prt"] = "port",
        ["lang"] = "language",
        ["fact"] = "factor",
        ["spec"] = "specification",
    };
}