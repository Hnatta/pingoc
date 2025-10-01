module("luci.controller.pingoc", package.seeall)
function index()
entry({"admin","services","pingoc"}, template("pingoc"), _("Ping OC"), 3).leaf=true
end