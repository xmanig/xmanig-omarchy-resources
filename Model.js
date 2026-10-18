function urlToPath(url) {
  var value = String(url)
  if (value.indexOf("file://") === 0) value = value.substring(7)
  return decodeURIComponent(value)
}

function numberOr(value, fallback) {
  var number = Number(value)
  return isFinite(number) ? number : fallback
}

function parseMetrics(text) {
  var metrics = {
    cpu: -1,
    cores: [],
    ram: -1,
    ramUsedKiB: 0,
    ramTotalKiB: 0,
    gpu: -1,
    vramUsed: 0,
    vramTotal: 0,
    gpuName: "Unavailable"
  }

  var lines = String(text || "").split(/\r?\n/)
  for (var i = 0; i < lines.length; i++) {
    var fields = lines[i].split("\t")
    if (fields.length === 0) continue

    if (fields[0] === "cpu" && fields.length >= 3) {
      metrics.cpu = numberOr(fields[1], -1)
      var coreValues = fields[2] ? fields[2].split(",") : []
      for (var c = 0; c < coreValues.length; c++) metrics.cores.push(numberOr(coreValues[c], 0))
    } else if (fields[0] === "ram" && fields.length >= 4) {
      metrics.ram = numberOr(fields[1], -1)
      metrics.ramUsedKiB = numberOr(fields[2], 0)
      metrics.ramTotalKiB = numberOr(fields[3], 0)
    } else if (fields[0] === "gpu" && fields.length >= 5) {
      metrics.gpu = numberOr(fields[1], -1)
      metrics.vramUsed = numberOr(fields[2], 0)
      metrics.vramTotal = numberOr(fields[3], 0)
      metrics.gpuName = fields.slice(4).join("\t") || "GPU"
    }
  }
  return metrics
}

function clampPercent(value) {
  return Math.max(0, Math.min(100, numberOr(value, 0)))
}

function formatPercent(value) {
  return value < 0 ? "—" : Math.round(clampPercent(value)) + "%"
}

function formatBytes(bytes) {
  var value = numberOr(bytes, 0)
  var units = ["B", "KiB", "MiB", "GiB", "TiB"]
  var unit = 0
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024
    unit++
  }
  return (unit === 0 ? Math.round(value) : value.toFixed(value >= 10 ? 0 : 1)) + " " + units[unit]
}

function formatKiB(kib) {
  return formatBytes(numberOr(kib, 0) * 1024)
}
