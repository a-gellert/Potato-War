var Type = {
  Zero: 0,
  Json: 1,
  String: 2,
  Integer: 3,
  Number: 4, // float
};

function packToJson(data) {
  if (data !== undefined && data !== null) {
    var obj = { data: data };
    var jsonStr = JSON.stringify(obj);
    if (typeof stringToNewUTF8 === 'function') {
      return stringToNewUTF8(jsonStr);
    }
    if (typeof Module !== 'undefined' && typeof Module.stringToNewUTF8 === 'function') {
      return Module.stringToNewUTF8(jsonStr);
    }
  }
  return 0;
}

function CStrOrNull(string) {
  if (string !== undefined && string !== null) {
    var str = String(string);
    if (typeof stringToNewUTF8 === 'function') {
      return stringToNewUTF8(str);
    }
    if (typeof Module !== 'undefined' && typeof Module.stringToNewUTF8 === 'function') {
      return Module.stringToNewUTF8(str);
    }
  }
  return 0;
}

if (typeof window !== 'undefined') {
  window.Type = Type;
  window.packToJson = packToJson;
  window.CStrOrNull = CStrOrNull;
}
if (typeof globalThis !== 'undefined') {
  globalThis.Type = Type;
  globalThis.packToJson = packToJson;
  globalThis.CStrOrNull = CStrOrNull;
}