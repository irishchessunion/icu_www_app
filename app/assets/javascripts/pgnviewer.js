/* Copyright 2007-2015 Richard Jones
 This work is licensed under the Creative Commons Attribution-Noncommercial-No Derivative Works License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/2.5/au/
 */
Gettext = function (t) {
    this.domain = "messages", this.locale_data = void 0;
    var e = ["domain", "locale_data"];
    if (this.isValidObject(t))for (var a in t)for (var r = 0; r < e.length; r++)a == e[r] && this.isValidObject(t[a]) && (this[a] = t[a]);
    return this.try_load_lang(), this
}, Gettext.context_glue = "", Gettext._locale_data = {}, Gettext.prototype.try_load_lang = function () {
    if ("undefined" != typeof this.locale_data) {
        var t = this.locale_data;
        if (this.locale_data = void 0, this.parse_locale_data(t), "undefined" == typeof Gettext._locale_data[this.domain])throw new Error("Error: Gettext 'locale_data' does not contain the domain '" + this.domain + "'")
    }
    var e = this.get_lang_refs();
    if ("object" == typeof e && e.length > 0)for (var a = 0; a < e.length; a++) {
        var r = e[a];
        if ("application/json" == r.type) {
            if (!this.try_load_lang_json(r.href))throw new Error("Error: Gettext 'try_load_lang_json' failed. Unable to exec xmlhttprequest for link [" + r.href + "]")
        } else {
            if ("application/x-po" != r.type)throw new Error("TODO: link type [" + r.type + "] found, and support is planned, but not implemented at this time.");
            if (!this.try_load_lang_po(r.href))throw new Error("Error: Gettext 'try_load_lang_po' failed. Unable to exec xmlhttprequest for link [" + r.href + "]")
        }
    }
}, Gettext.prototype.parse_locale_data = function (t) {
    "undefined" == typeof Gettext._locale_data && (Gettext._locale_data = {});
    for (var e in t)if (t.hasOwnProperty(e) && this.isValidObject(t[e])) {
        var a = !1;
        for (var r in t[e]) {
            a = !0;
            break
        }
        if (a) {
            var n = t[e];
            "" == e && (e = "messages"), this.isValidObject(Gettext._locale_data[e]) || (Gettext._locale_data[e] = {}), this.isValidObject(Gettext._locale_data[e].head) || (Gettext._locale_data[e].head = {}), this.isValidObject(Gettext._locale_data[e].msgs) || (Gettext._locale_data[e].msgs = {});
            for (var i in n)if ("" == i) {
                var o = n[i];
                for (var s in o) {
                    var l = s.toLowerCase();
                    Gettext._locale_data[e].head[l] = o[s]
                }
            } else Gettext._locale_data[e].msgs[i] = n[i]
        }
    }
    for (var e in Gettext._locale_data)if (this.isValidObject(Gettext._locale_data[e].head["plural-forms"]) && "undefined" == typeof Gettext._locale_data[e].head.plural_func) {
        var p = Gettext._locale_data[e].head["plural-forms"], d = new RegExp("^(\\s*nplurals\\s*=\\s*[0-9]+\\s*;\\s*plural\\s*=\\s*(?:\\s|[-\\?\\|&=!<>+*/%:;a-zA-Z0-9_()])+)", "m");
        if (!d.test(p))throw new Error("Syntax error in language file. Plural-Forms header is invalid [" + p + "]");
        var u = Gettext._locale_data[e].head["plural-forms"];
        /;\s*$/.test(u) || (u = u.concat(";"));
        var c = "var plural; var nplurals; " + u + ' return { "nplural" : nplurals, "plural" : (plural === true ? 1 : plural ? plural : 0) };';
        Gettext._locale_data[e].head.plural_func = new Function("n", c)
    } else"undefined" == typeof Gettext._locale_data[e].head.plural_func && (Gettext._locale_data[e].head.plural_func = function (t) {
        var e = 1 != t ? 1 : 0;
        return {nplural: 2, plural: e}
    })
}, Gettext.prototype.try_load_lang_po = function (t) {
    var e = this.sjax(t);
    if (e) {
        var a = this.uri_basename(t), r = this.parse_po(e), n = {};
        return r && (r[""] || (r[""] = {}), r[""].domain || (r[""].domain = a), a = r[""].domain, n[a] = r, this.parse_locale_data(n)), 1
    }
}, Gettext.prototype.uri_basename = function (t) {
    var e;
    if (e = t.match(/^(.*\/)?(.*)/)) {
        var a;
        return (a = e[2].match(/^(.*)\..+$/)) ? a[1] : e[2]
    }
    return ""
}, Gettext.prototype.parse_po = function (t) {
    for (var e = {}, a = {}, r = "", n = [], i = t.split("\n"), o = 0; o < i.length; o++) {
        i[o] = i[o].replace(/(\n|\r)+$/, "");
        var s;
        if (/^$/.test(i[o])) {
            if ("undefined" != typeof a.msgid) {
                var l = "undefined" != typeof a.msgctxt && a.msgctxt.length ? a.msgctxt + Gettext.context_glue + a.msgid : a.msgid, p = "undefined" != typeof a.msgid_plural && a.msgid_plural.length ? a.msgid_plural : null, d = [];
                for (var u in a) {
                    var s;
                    (s = u.match(/^msgstr_(\d+)/)) && (d[parseInt(s[1])] = a[u])
                }
                d.unshift(p), d.length > 1 && (e[l] = d), a = {}, r = ""
            }
        } else {
            if (/^#/.test(i[o]))continue;
            (s = i[o].match(/^msgctxt\s+(.*)/)) ? (r = "msgctxt", a[r] = this.parse_po_dequote(s[1])) : (s = i[o].match(/^msgid\s+(.*)/)) ? (r = "msgid", a[r] = this.parse_po_dequote(s[1])) : (s = i[o].match(/^msgid_plural\s+(.*)/)) ? (r = "msgid_plural", a[r] = this.parse_po_dequote(s[1])) : (s = i[o].match(/^msgstr\s+(.*)/)) ? (r = "msgstr_0", a[r] = this.parse_po_dequote(s[1])) : (s = i[o].match(/^msgstr\[0\]\s+(.*)/)) ? (r = "msgstr_0", a[r] = this.parse_po_dequote(s[1])) : (s = i[o].match(/^msgstr\[(\d+)\]\s+(.*)/)) ? (r = "msgstr_" + s[1], a[r] = this.parse_po_dequote(s[2])) : /^"/.test(i[o]) ? a[r] += this.parse_po_dequote(i[o]) : n.push("Strange line [" + o + "] : " + i[o])
        }
    }
    if ("undefined" != typeof a.msgid) {
        var l = "undefined" != typeof a.msgctxt && a.msgctxt.length ? a.msgctxt + Gettext.context_glue + a.msgid : a.msgid, p = "undefined" != typeof a.msgid_plural && a.msgid_plural.length ? a.msgid_plural : null, d = [];
        for (var u in a) {
            var s;
            (s = u.match(/^msgstr_(\d+)/)) && (d[parseInt(s[1])] = a[u])
        }
        d.unshift(p), d.length > 1 && (e[l] = d), a = {}, r = ""
    }
    if (e[""] && e[""][1]) {
        for (var c = {}, f = e[""][1].split(/\\n/), o = 0; o < f.length; o++)if (f.length) {
            var h = f[o].indexOf(":", 0);
            if (-1 != h) {
                var _ = f[o].substring(0, h), x = f[o].substring(h + 1), g = _.toLowerCase();
                c[g] && c[g].length ? n.push("SKIPPING DUPLICATE HEADER LINE: " + f[o]) : /#-#-#-#-#/.test(g) ? n.push("SKIPPING ERROR MARKER IN HEADER: " + f[o]) : (x = x.replace(/^\s+/, ""), c[g] = x)
            } else n.push("PROBLEM LINE IN HEADER: " + f[o]), c[f[o]] = ""
        }
        e[""] = c
    } else e[""] = {};
    return e
}, Gettext.prototype.parse_po_dequote = function (t) {
    var e;
    return (e = t.match(/^"(.*)"/)) && (t = e[1]), t = t.replace(/\\"/, "")
}, Gettext.prototype.try_load_lang_json = function (t) {
    var e = this.sjax(t);
    if (e) {
        var a = this.JSON(e);
        return this.parse_locale_data(a), 1
    }
}, Gettext.prototype.get_lang_refs = function () {
    for (var t = new Array, e = document.getElementsByTagName("link"), a = 0; a < e.length; a++)if ("gettext" == e[a].rel && e[a].href) {
        if ("undefined" == typeof e[a].type || "" == e[a].type)if (/\.json$/i.test(e[a].href))e[a].type = "application/json"; else if (/\.js$/i.test(e[a].href))e[a].type = "application/json"; else if (/\.po$/i.test(e[a].href))e[a].type = "application/x-po"; else {
            if (!/\.mo$/i.test(e[a].href))throw new Error("LINK tag with rel=gettext found, but the type and extension are unrecognized.");
            e[a].type = "application/x-mo"
        }
        if (e[a].type = e[a].type.toLowerCase(), "application/json" == e[a].type)e[a].type = "application/json"; else if ("text/javascript" == e[a].type)e[a].type = "application/json"; else if ("application/x-po" == e[a].type)e[a].type = "application/x-po"; else {
            if ("application/x-mo" != e[a].type)throw new Error("LINK tag with rel=gettext found, but the type attribute [" + e[a].type + "] is unrecognized.");
            e[a].type = "application/x-mo"
        }
        t.push(e[a])
    }
    return t
}, Gettext.prototype.textdomain = function (t) {
    return t && t.length && (this.domain = t), this.domain
}, Gettext.prototype.gettext = function (t) {
    var e, a, r, n;
    return this.dcnpgettext(null, e, t, a, r, n)
}, Gettext.prototype.dgettext = function (t, e) {
    var a, r, n, i;
    return this.dcnpgettext(t, a, e, r, n, i)
}, Gettext.prototype.dcgettext = function (t, e, a) {
    var r, n, i;
    return this.dcnpgettext(t, r, e, n, i, a)
}, Gettext.prototype.ngettext = function (t, e, a) {
    var r, n;
    return this.dcnpgettext(null, r, t, e, a, n)
}, Gettext.prototype.dngettext = function (t, e, a, r) {
    var n, i;
    return this.dcnpgettext(t, n, e, a, r, i)
}, Gettext.prototype.dcngettext = function (t, e, a, r, n) {
    var i;
    return this.dcnpgettext(t, i, e, a, r, n, n)
}, Gettext.prototype.pgettext = function (t, e) {
    var a, r, n;
    return this.dcnpgettext(null, t, e, a, r, n)
}, Gettext.prototype.dpgettext = function (t, e, a) {
    var r, n, i;
    return this.dcnpgettext(t, e, a, r, n, i)
}, Gettext.prototype.dcpgettext = function (t, e, a, r) {
    var n, i;
    return this.dcnpgettext(t, e, a, n, i, r)
}, Gettext.prototype.npgettext = function (t, e, a, r) {
    var n;
    return this.dcnpgettext(null, t, e, a, r, n)
}, Gettext.prototype.dnpgettext = function (t, e, a, r, n) {
    var i;
    return this.dcnpgettext(t, e, a, r, n, i)
}, Gettext.prototype.dcnpgettext = function (t, e, a, r, n, i) {
    if (!this.isValidObject(a))return "";
    var o = this.isValidObject(r), s = this.isValidObject(e) ? e + Gettext.context_glue + a : a, l = this.isValidObject(t) ? t : this.isValidObject(this.domain) ? this.domain : "messages", p = new Array;
    if ("undefined" != typeof Gettext._locale_data && this.isValidObject(Gettext._locale_data[l]))p.push(Gettext._locale_data[l]); else if ("undefined" != typeof Gettext._locale_data)for (var d in Gettext._locale_data)p.push(Gettext._locale_data[d]);
    var u, c = [], f = !1;
    if (p.length)for (var h = 0; h < p.length; h++) {
        var _ = p[h];
        if (this.isValidObject(_.msgs[s])) {
            for (var x = 0; x < _.msgs[s].length; x++)c[x] = _.msgs[s][x];
            if (c.shift(), u = _, f = !0, c.length > 0 && 0 != c[0].length)break
        }
    }
    (0 == c.length || 0 == c[0].length) && (c = [a, r]);
    var g = c[0];
    if (o) {
        var m;
        if (f && this.isValidObject(u.head.plural_func)) {
            var y = u.head.plural_func(n);
            y.plural || (y.plural = 0), y.nplural || (y.nplural = 0), y.nplural <= y.plural && (y.plural = 0), m = y.plural
        } else m = 1 != n ? 1 : 0;
        this.isValidObject(c[m]) && (g = c[m])
    }
    return g
}, Gettext.strargs = function (t, e) {
    null == e || "undefined" == typeof e ? e = [] : e.constructor != Array && (e = [e]);
    for (var a = ""; ;) {
        var r, n = t.indexOf("%");
        if (-1 == n) {
            a += t;
            break
        }
        if (a += t.substr(0, n), "%%" == t.substr(n, 2))a += "%", t = t.substr(n + 2); else if (r = t.substr(n).match(/^%(\d+)/)) {
            var i = parseInt(r[1]), o = r[1].length;
            i > 0 && null != e[i - 1] && "undefined" != typeof e[i - 1] && (a += e[i - 1]), t = t.substr(n + 1 + o)
        } else a += "%", t = t.substr(n + 1)
    }
    return a
}, Gettext.prototype.strargs = function (t, e) {
    return Gettext.strargs(t, e)
}, Gettext.prototype.isArray = function (t) {
    return this.isValidObject(t) && t.constructor == Array
}, Gettext.prototype.isValidObject = function (t) {
    return null == t ? !1 : "undefined" == typeof t ? !1 : !0
}, Gettext.prototype.sjax = function (t) {
    var e;
    if (e = window.XMLHttpRequest ? new XMLHttpRequest : new ActiveXObject(-1 != navigator.userAgent.toLowerCase().indexOf("msie 5") ? "Microsoft.XMLHTTP" : "Msxml2.XMLHTTP"), !e)throw new Error("Your browser doesn't do Ajax. Unable to support external language files.");
    e.open("GET", t, !1);
    try {
        e.send(null)
    } catch (a) {
        return
    }
    var r = e.status;
    if (200 == r || 0 == r)return e.responseText;
    var n = e.statusText + " (Error " + e.status + ")";
    return e.responseText.length && (n += "\n" + e.responseText), void alert(n)
}, Gettext.prototype.JSON = function (data) {
    return eval("(" + data + ")")
};
CTSound = function (a) {
    this.sounds = [], this.soundPath = a.soundPath;
    var n = (!!(myAudioTag = document.createElement("audio")).canPlayType, null);
    "undefined" != typeof Audio && (n = new Audio("")), this.haveAudio = n && !!n.canPlayType, this.haveAudio && (this.canPlayOgg = "no" != n.canPlayType("audio/ogg") && "" != n.canPlayType("audio/ogg"), this.canPlayMp3 = "no" != n.canPlayType("audio/mpeg") && "" != n.canPlayType("audio/mpeg"), this.canPlayWav = "no" != n.canPlayType("audio/wav") && "" != n.canPlayType("audio/wav"))
}, CTSound.prototype.createSound = function (a, n) {
    if (this.haveAudio) {
        var o = null, i = "";
        this.canPlayMp3 ? i = this.soundPath + "/" + a + ".mp3" : this.canPlayOgg ? i = this.soundPath + "/" + a + ".ogg" : this.canPlayWav && (i = this.soundPath + "/" + a + ".wav"), i && (o = new Audio(i)), o && (o.id = n + "-" + a, this.sounds[a] = o, n && (this.sounds[n] = o))
    }
}, CTSound.prototype.playSound = function (a) {
    var n = this.sounds[a];
    n && n.play()
};
function getLocale() {
    if (navigator) {
        if (navigator.language)return navigator.language;
        if (navigator.browserLanguage)return navigator.browserLanguage;
        if (navigator.systemLanguage)return navigator.systemLanguage;
        if (navigator.userLanguage)return navigator.userLanguage
    }
}
function init_gettext() {
    if ("undefined" != typeof json_locale_data) {
        var n = {domain: "js-messages", locale_data: json_locale_data};
        gt = new Gettext(n)
    }
}
function _js(n) {
    return gt ? gt.gettext(n) : n
}

function _has_translation(n) {
    var t = getLocale();
    if (t) {
        var a = t.substring(0, 2);
        return "en" == a || n != _js(n)
    }
    return !0
}
function __js(n, t) {
    for (var n = _js(n), a = 0; a < t.length; a++) {
        var e = new RegExp("{" + t[a][0] + "}", "g");
        n = n.replace(e, t[a][1])
    }
    return n
}
function _jn(n, t, a) {
    var e;
    return e = gt ? gt.ngettext(n, t, a) : 0 == a || a > 1 ? t : n
}
function __jn(n, t, a, e) {
    var r = _jn(n, t, a);
    return __gt_expand(r, e)
}
function __gt_expand(n, t) {
    for (var a = 0; a < t.length; a++) {
        var e = new RegExp("{" + t[a][0] + "}", "g");
        n = n.replace(e, t[a][1])
    }
    return n
}
var gt = null;
init_gettext();
PgnViewer = function (e, r) {
    var t = new BoardConfig;
    e && t.applyConfig(e), window._pvObject || (window._pvObject = new Array), window._pvObject[t.boardName] = this, e = t, e.pgnMode = !0, e.scrollVariations = !0, this.chessapp = new ChessApp(e), this.finishedCallback = r, e.loadImmediately ? (this.chessapp.init(null, null, null, this, !0), this.board = this.chessapp.board) : YAHOO.util.Event.onDOMReady(this.setup, this, !0)
}, PgnViewer.prototype.setup = function () {
    this.chessapp.init(null, null, null, this, !0), this.board = this.chessapp.board
}, PgnViewer.prototype.updatePieceCallback = function (e, r, t, s, a, i, o, n, h, l, d, c) {
    var b = new Object, u = d, g = !1, p = Board.getVarMove(u, s, t, r, e);
    return u.fromColumn != r.column || u.fromRow != r.row || u.toRow != s || u.toColumn != t || "" != e && e != u.promotion ? p && (u = p, g = !0) : g = !0, b.move = u, b.allowMove = g, b.dontMakeOpponentMove = !1, b
}, PgnViewer.prototype.setupFromPgn = function (e, r) {
    this.chessapp.pgn.setupFromPGN(e, r)
}, PgnViewer.prototype.setupFromFen = function (e, r, t, s) {
    this.chessapp.pgn.board.setupFromFen(e, r, t, s)
}, PGNGame = function (e, r, t, s, a, i, o, n, h, l, d, c, b) {
    this.movesseq = e, this.startFen = r, this.blackPlayer = t, this.whitePlayer = s, this.pgn_result = a, this.event = i, this.site = o, this.date = n, this.round = h, this.start_movenum = l, this.whitePlayerElo = d, this.blackPlayerElo = c, this.eco = b
}, PGN = function (e) {
    this.board = e, this.pgnGames = new Array, this.lastShownGame = 0
}, PGN.prototype.pollPGNFromURL = function (e, r, t) {
    var s = this;
    return this.getPGNFromURL(e, r), this.foundResult && (t = this.board.pollPGNMillisecondsPostResult, this.foundResultPolls++), this.foundResultPolls >= this.board.numberPollsAfterResult ? void(this.finishedPolling = !0) : (this.pollTime = t, this.lastPoll = (new Date).getTime(), void setTimeout(function () {
        s.pollPGNFromURL(e, r, t)
    }, t))
}, PGN.prototype.getPGNFromURL = function (url, gotoEnd) {
    var randString = (new Date).getTime() + "-" + parseInt(99999 * Math.random());
    YAHOO.util.Connect.asyncRequest("GET", url + "?rs=" + randString, {
        success: function (o) {
            var resTag = "", site = "", moveText = "", re = eval("/\\n[^[]/");
            o.responseText.indexOf("\r") >= 0 && eval("/\\r[^[]/");
            var ind = o.responseText.search(re);
            if (ind >= 0 && (moveText = o.responseText.substring(ind)), re = eval("/\\[Result /"), ind = o.responseText.search(re), ind >= 0) {
                var ind2 = o.responseText.indexOf("\n", ind);
                0 > ind2 && (ind2 = o.responseText.indexOf("\r", ind)), ind2 >= 0 && (resTag = o.responseText.substring(ind, ind2))
            }
            if (re = eval("/\\[Site /"), ind = o.responseText.search(re), ind >= 0) {
                var ind2 = o.responseText.indexOf("]", ind);
                ind2 >= 0 && (site = o.responseText.substring(ind + 6, ind2 - 1))
            }
            if (site)if (this.board.fideClock) {
                var whiteClock = YAHOO.util.Dom.get(this.board.boardName + "-whitePlayerClock"), blackClock = YAHOO.util.Dom.get(this.board.boardName + "-blackPlayerClock"), ss = site.split("-"), whiteTime = ss[0], blackTime = "0";
                '"' == whiteTime.charAt(0) && (whiteTime = whiteTime.substr(1)), ss.length > 1 && (blackTime = ss[1]), whiteClock && (whiteClock.innerHTML = whiteTime), blackClock && (blackClock.innerHTML = blackTime)
            } else {
                var siteDiv = YAHOO.util.Dom.get(this.board.boardName + "-site");
                siteDiv && (siteDiv.innerHTML = site)
            }
            (this.currentMoveText != moveText || this.currentResultTag != resTag) && (this.currentMoveText = moveText, this.currentResultTag = resTag, this.setupFromPGN(o.responseText, gotoEnd))
        }, failure: function (e) {
            this.board.hidePGNErrors || alert("pgn load failed:" + e.statusText + " for file:" + url)
        }, scope: this
    }, "rs2=" + randString)
}, PGN.prototype.getMoveFromPGNMove = function (e, r, t) {
    var s, a = !1, i = !1, o = !1, n = null, h = !1, l = null;
    if ("#" == e.charAt(e.length - 1) ? (i = !0, a = !0, e = e.substr(0, e.length - 1)) : "+" == e.charAt(e.length - 1) && (i = !0, e.length > 1 && "+" == e.charAt(e.length - 2) ? (a = !0, e = e.substr(0, e.length - 2)) : e = e.substr(0, e.length - 1)), "O-O-O" == e)return this.board.createMoveFromString("w" == r ? "e1c1" : "e8c8");
    if ("O-O" == e)return this.board.createMoveFromString("w" == r ? "e1g1" : "e8g8");
    var d = e.indexOf("=");
    if (d >= 0) {
        var c;
        n = e.substr(d + 1, 1), c = n.charAt(0), s = this.board.pieceCharToPieceNum(c), o = !0, e = e.substr(0, d)
    }
    var b = e.charAt(e.length - 1);
    ("Q" == b || "R" == b || "N" == b || "B" == b) && (n = b + "", s = this.board.pieceCharToPieceNum(n), o = !0, e = e.substr(0, e.length - 1));
    var u = e.substr(e.length - 2, 2), g = u.charCodeAt(0) - "a".charCodeAt(0), p = u.charCodeAt(1) - "1".charCodeAt(0);
    if (g > 7 || 0 > g || p > 7 || 0 > p)return this.lastMoveFromError = __js("Error processing to Square:{TO_SQUARE} on move:{MOVE}", [["TO_SQUARE", u], ["MOVE", e]]), null;
    e.length > 2 && ("x" == e.charAt(e.length - 3) ? (h = !0, l = e.substr(0, e.length - 3)) : l = e.substr(0, e.length - 2));
    var m = new Array, v = 0, f = null, P = "w" == r ? ChessPiece.WHITE : ChessPiece.BLACK;
    switch (e.charAt(0)) {
        case"K":
        case"k":
            f = ChessPiece.KING;
            break;
        case"Q":
        case"q":
            f = ChessPiece.QUEEN;
            break;
        case"R":
        case"r":
            f = ChessPiece.ROOK;
            break;
        case"B":
            f = ChessPiece.BISHOP;
            break;
        case"N":
        case"n":
            f = ChessPiece.KNIGHT;
            break;
        case"P":
        case"p":
            f = ChessPiece.PAWN;
            break;
        default:
            f = ChessPiece.PAWN
    }
    var A = null, O = null;
    if (l) {
        var w = l.toLowerCase().charAt(0);
        if (w == l.charAt(0) && w >= "a" && "h" >= w)O = w, 2 == l.length && (A = l.charAt(1)); else if (l.length > 1)if (2 == l.length) {
            var M = l.charAt(1);
            M >= "1" && "8" >= M ? A = M : O = M
        } else {
            if (3 != l.length)return this.lastMoveFromError = __js("Error: unhandled fromChars:{FROM_CHARS}", [["FROM_CHARS", l]]), null;
            if (O = l.charAt(1), A = l.charAt(2), O >= "1" && "9" >= O) {
                var T = O;
                O = A, A = T
            }
        }
    }
    for (var C = 0; 8 > C; C++)for (var N = 0; 8 > N; N++) {
        var k = this.board.boardPieces[C][N];
        if (null != k && k.colour == P && k.piece == f && this.board.canMove(k, g, p, t, !0)) {
            var G = String.fromCharCode("a".charCodeAt(0) + C).charAt(0), y = String.fromCharCode("1".charCodeAt(0) + N).charAt(0);
            null != O && O != G || null != A && A != y || (m[v++] = k)
        }
    }
    if (0 == v)return this.lastMoveFromError = __js("no candidate pieces for:{MOVE}", [["MOVE", e]]), null;
    if (v > 1)return this.lastMoveFromError = __js("Ambiguous:{MOVE} with fromChars:{FROM_CHARS} disambigRow:{DISAMBIG_ROW} disambigCol:{DISAMBIG_COL}", [["MOVE", e], ["FROM_CHARS", l], ["DISAMBIG_ROW", A], ["DISAMBIG_COL", O]]), null;
    var E = m[0], R = "";
    R += String.fromCharCode("a".charCodeAt(0) + E.column), R += String.fromCharCode("1".charCodeAt(0) + E.row), h && (R += "x"), R += u, n && (R += n);
    var F = this.board.createMoveFromString(R);
    return F
}, PGN.prototype.parseTag = function (e, r, t) {
    if (r.substr(t, e.length + 3) == "[" + e + ' "') {
        var s = r.indexOf('"', t + e.length + 3);
        if (s >= 0)return r.substring(t + e.length + 3, s)
    }
    return null
}, PGN.prototype.parsePGN = function (e, r, t) {
    ctime && console.time("parsePGN"), e = e.replace(/&nbsp;/g, " "), e = e.replace(/^\s+|\s+$/g, "");
    var s = 0;
    this.pgn = e;
    var a = new Array, i = 1, o = 0;
    this.pgnGames = new Array, this.finishedParseCallback = r, this.startParseTime = (new Date).getTime();
    var n = this.parsePGN_cont(a, i, o, s, t), h = new Object;
    return n ? (h.parsedOk = !1, h.errorString = n, h.pgnGames = null) : (h.parsedOk = !0, h.pgnGames = this.pgnGames), ctime && console.timeEnd("parsePGN"), h
}, PGN.prototype.parsePGN_cont = function (e, r, t, s, a) {
    for (var i = this.pgn, o = this.board.boardName + "-progress", n = YAHOO.util.Dom.get(o); s < i.length;) {
        var h = "", l = "", d = "", c = "", b = "", u = "?", g = "", p = "?", m = "?", v = "", f = "w", P = 0, A = 0, O = (new Array, 0), w = "", M = null, T = null, C = new Array, N = new Array, k = new Array, G = new Array, y = new Array;
        this.board.pieceMoveDisabled = !0, this.board.startFen = this.board.initialFen ? this.board.initialFen : "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
        var E = 0;
        for (E = s; E < i.length; E++) {
            var R = this.parseTag("FEN", i, E);
            if (R && "?" != R ? this.board.startFen = R : (R = this.parseTag("White", i, E), R && "?" != R ? g = R : (R = this.parseTag("Black", i, E), R && "?" != R ? l = R : (R = this.parseTag("Result", i, E), R && "?" != R ? h = R : (R = this.parseTag("Event", i, E), R && "?" != R ? d = R : (R = this.parseTag("Site", i, E), R && "?" != R ? c = R : (R = this.parseTag("Date", i, E), R && "?" != R ? b = R : (R = this.parseTag("Round", i, E), R && "?" != R ? u = R : (R = this.parseTag("WhiteElo", i, E), R && "?" != R ? p = R : (R = this.parseTag("BlackElo", i, E), R && "?" != R ? m = R : (R = this.parseTag("ECO", i, E), R && "?" != R && (v = R))))))))))), "[" != i.charAt(E))if ("{" != i.charAt(E)) {
                if ("." == i.substr(E, 1)) {
                    for (var F = E - 1; F >= 0 && i.charAt(F) >= "0" && i.charAt(F) <= "9";)F--;
                    F++, i.charAt(F) >= "0" && i.charAt(F) <= "9" && (r = parseInt(i.substring(F, E)));
                    break
                }
            } else {
                var _ = i.indexOf("}", E + 1);
                if (!(_ >= 0)) {
                    var H = _js("PgnViewer: Error parsing PGN. Found unclosed {");
                    return this.finishedParseCallback && this.finishedParseCallback(a, H), H
                }
                var S = i.substring(E + 1, _);
                E = _, w += "{ " + S + " } "
            } else {
                var F;
                for (F = E + 1; F < i.length && "]" != i.charAt(F); F++);
                if (F == i.length) {
                    var H = _js("PgnViewer: Error parsing PGN. Found unclosed [");
                    return this.finishedParseCallback && this.finishedParseCallback(a, H), H
                }
                E = F - 1
            }
        }
        "." != i.substr(E, 1), this.board.prev_move = null, this.board.setupFromFen(this.board.startFen, !1, !1, !0, !0), M = this.board.prev_move;
        var D = E, x = null;
        for (E = E; E < i.length; E++) {
            var L = -1;
            if ("1-0" == i.substr(E, 3) || "0-1" == i.substr(E, 3) ? L = 3 : "1/2-1/2" == i.substr(E, 7) ? L = 7 : "*" == i.substr(E, 1) && (L = 1), L > 0) {
                x = i.substr(E, L), s = E + L;
                break
            }
            if ("[" == i.charAt(E)) {
                s = E;
                break
            }
            if (" " != i.charAt(E) && "	" != i.charAt(E) && "\n" != i.charAt(E) && "\r" != i.charAt(E)) {
                if (!(i.charAt(E) >= "0" && i.charAt(E) <= "9"))if ("." == i.charAt(E)) {
                    {
                        i.substring(D, E).replace(/^\s+|\s+$/g, "")
                    }
                    for (D = E; E + 1 < i.length && "." == i.charAt(E + 1);)E++;
                    f = D != E ? "b" : "w", D = E + 1
                } else if ("{" == i.charAt(E)) {
                    var _ = i.indexOf("}", E + 1);
                    if (_ >= 0) {
                        var S = i.substring(E + 1, _);
                        E = _, w += "{ " + S + " } "
                    }
                    D = E + 1
                } else if ("(" == i.charAt(E))C[P] = this.board.boardPieces, N[P] = f, G[P] = M, y[P] = T, this.board.boardPieces = k[P], this.board.boardPieces = this.board.copyBoardPieces(!1), M = T, P++, D = E + 1, w += "( "; else if (")" == i.charAt(E))boardPool.putObject(C[P]), P--, this.board.boardPieces = C[P], f = N[P], M = G[P], T = y[P], D = E + 1, w += ") "; else {
                    if ("$" == i.charAt(E)) {
                        var F;
                        for (F = E + 1; F < i.length && i.charAt(F) >= "0" && i.charAt(F) <= "9"; F++);
                        if (F--, F > E) {
                            var I = parseInt(i.substr(E + 1, F + 1));
                            if (9 >= I)switch (I) {
                                case 1:
                                    w = w.substr(0, w.length - 1) + "! ";
                                    break;
                                case 2:
                                    w = w.substr(0, w.length - 1) + "? ";
                                    break;
                                case 3:
                                    w = w.substr(0, w.length - 1) + "!! ";
                                    break;
                                case 4:
                                    w = w.substr(0, w.length - 1) + "?? ";
                                    break;
                                case 5:
                                    w = w.substr(0, w.length - 1) + "!? ";
                                    break;
                                case 6:
                                    w = w.substr(0, w.length - 1) + "?! ";
                                    break;
                                case 7:
                                case 8:
                                case 9:
                                case 0:
                            } else w += i.substring(E, F + 1) + " ";
                            E = F
                        }
                        continue
                    }
                    for (var Y = -1, F = E + 1; F < i.length; F++)if (")" == i.charAt(F) || "(" == i.charAt(F) || "{" == i.charAt(F) || "}" == i.charAt(F) || " " == i.charAt(F) || "	" == i.charAt(F) || "\n" == i.charAt(F) || "\r" == i.charAt(F)) {
                        Y = F;
                        break
                    }
                    -1 == Y && (Y = i.length);
                    var V = D, B = i.substring(D, Y).replace(/^\s+|\s+$/g, "");
                    if (D = Y, E = D - 1, B.length >= 4 && "e.p." == B.substring(0, 4))continue;
                    if (0 == B.length) {
                        var H = __js("PgnViewer: Error: got empty move endMoveInd:{ENDMOVE_INDEX} upto:{UPTO} from:{FROM}", [["ENDMOVE_INDEX", Y], ["UPTO", V], ["FROM", i.substr(V)]]);
                        return this.finishedParseCallback && this.finishedParseCallback(a, H), H
                    }
                    for (var j = B.length - 1; j >= 0;)if ("?" == B.charAt(j))j--; else {
                        if ("!" != B.charAt(j))break;
                        j--
                    }
                    var U = B.substring(0, j + 1), q = this.getMoveFromPGNMove(U, f, M);
                    if (null == q) {
                        w += "unknown ";
                        var H = __js("PgnViewer: Error parsing:{MOVE}, {ERROR_REASON}", [["MOVE", B], ["ERROR_REASON", this.lastMoveFromError]]);
                        return this.finishedParseCallback && this.finishedParseCallback(a, H), H
                    }
                    T = M, M = q;
                    var K = this.board.boardPieces[q.fromColumn][q.fromRow];
                    boardPool.putObject(k[P]), k[P] = this.board.copyBoardPieces(!1), K && this.board.makeMove(q, K, !1, .5, !1, !1), A = P, O++, f = this.board.flipToMove(f), w += q.moveString + "|" + B + " "
                }
            } else D = E + 1
        }
        E > s && (s = E);
        var Q = i.indexOf("{", s), W = i.indexOf("[", s);
        if (Q >= 0 && (-1 == W || W > Q)) {
            var $ = i.indexOf("}", Q + 1);
            if (!($ >= 0)) {
                var H = _js("PgnViewer: Error: Unclosed {");
                return this.finishedParseCallback && this.finishedParseCallback(a, H), H
            }
            var S = i.substring(Q + 1, $);
            s = $ + 1, w += "{ " + S + " } "
        }
        if (w = w.replace(/^\s+|\s+$/g, ""), this.board.pieceMoveDisabled = !1, null != x && (0 == h.length || "?" == h) && (h = x), this.board.ignoreMultipleGames && x && h && "*" == h && "*" != x && "?" != x && "" != x && (h = x), this.pgnGames[t++] = new PGNGame(w, this.board.startFen, l, g, h, d, c, b, u, r, p, m, v), n && (n.innerHTML = "Loaded " + t + " games"), this.board.ignoreMultipleGames)break;
        if (this.finishedParseCallback && (new Date).getTime() - this.startParseTime > 500)return this.startParseTime = (new Date).getTime(), void setTimeout('window._pvObject["' + this.board.boardName + '"].chessapp.pgn.parsePGN_cont("' + e + '","' + r + '","' + t + '","' + s + '",' + a + ");", 0)
    }
    return this.finishedParseCallback && this.finishedParseCallback(a), !1
}, PGN.prototype.setupFromPGN = function (e, r) {
    this.parsePGN(e, this.setupFromPGNCallback, r)
}, PGN.prototype.setupFromPGNCallback = function (e, r) {
    var t = this.board.boardName + "-progress", s = YAHOO.util.Dom.get(t);
    if (r) {
        if (!this.board.hidePGNErrors) {
            var a = YAHOO.util.Dom.get(this.board.boardName + "-pgnError");
            a ? a.innerHTML = r : alert(r)
        }
        return !1
    }
    if (0 == this.pgnGames.length)return this.board.hidePGNErrors || alert("PgnViewer: Error: Unable to find any pgn games in:" + pgn), !1;
    if (1 == this.pgnGames.length || this.board.ignoreMultipleGames) {
        var o = 0;
        e && (o = -1), this.showGame(0, o)
    } else {
        var n = this.board.boardName + "-container", h = YAHOO.util.Dom.get(n), l = YAHOO.util.Dom.get(this.board.boardName + "-problemSelector"), d = document.createElement("div"), c = '<form id="' + this.board.boardName + '-problemSelectorForm" action="" method="">', b = '<select id="' + this.board.boardName + '-problemSelector" name="' + this.board.boardName + '-problemSelector" style="width: ' + 8 * this.board.pieceSize + 'px;">', u = "";
        for (i = 0; i < this.pgnGames.length; i++) {
            var g = this.pgnGames[i], p = this.board.boardName + "-game-" + i, m = i + 1 + ". " + g.whitePlayer + " vs " + g.blackPlayer;
            g.pgn_result.length > 0 && "?" != g.pgn_result && 1 == this.board.showResult && (m += " " + g.pgn_result), g.event.length > 0 && "?" != g.event && 1 == this.board.showEvent && (m += " " + g.event), g.round.length > 0 && "?" != g.round && 1 == this.board.showRound && (m += " Rnd:" + g.round), g.site.length > 0 && "?" != g.site && 1 == this.board.showSite && (m += " " + g.site), g.date.length > 0 && "?" != g.date && 1 == this.board.showDate && (m += " " + g.date);
            var v = "";
            i == this.lastShownGame && (v = 'selected=""'), u += "<option " + v + ' id="' + p + '" value="' + i + '">' + m + "</option>"
        }
        l ? this.board.selectorBody != u && (l.innerHTML = u, this.board.selectorBody = u) : (c += b + u + "</select></form>", d.innerHTML = c, h.insertBefore(d, h.firstChild), this.board.selectorBody = u);
        var l = YAHOO.util.Dom.get(this.board.boardName + "-problemSelector");
        YAHOO.util.Event.addListener(l, "change", this.selectGame, this, !0);
        var o = 0, f = 0;
        e && (o = -1, f = this.lastShownGame), this.showGame(f, o)
    }
    s && YAHOO.util.Dom.setStyle(s, "visibility", "hidden"), window._pvObject[this.board.boardName].finishedCallback && window._pvObject[this.board.boardName].finishedCallback()
}, PGN.prototype.selectGame = function (e) {
    var r = YAHOO.util.Event.getTarget(e).selectedIndex, t = 0;
    this.board.gotoEndOnRefresh && (t = -1), this.showGame(r, t);
    var s = this.board.boardName + "-piecestaken", a = YAHOO.util.Dom.get(s);
    a && (a.innerHTML = ""), this.board.resetMoveListScrollPosition()
}, PGN.prototype.showGame = function (e, r) {
    r = "undefined" == typeof r ? 0 : r;
    var t = this.lastShownGame;
    this.lastShownGame = e;
    var s = this.board.moveArray, a = this.board.currentMove, i = !1;
    a && a.atEnd && (i = !0);
    var o = this.pgnGames[e], n = o.pgn_result;
    !n || "1/2-1/2" != n && "0-1" != n && "1-0" != n ? (this.foundResult = !1, this.foundResultPolls = 0) : this.foundResult = !0, this.board.startFen = o.startFen, this.board.setupFromFen(o.startFen, !1, !1, !1), this.board.setMoveSequence(o.movesseq, "NA", o.start_movenum, o.pgn_result);
    var h = !0, l = -1;
    if (e == t && i && (l = this.board.moveArray.length - 1), Move.moveArraysEqual(s, this.board.moveArray)) {
        var d = Move.findMoveInNewArray(s, this.board.moveArray, a);
        d && d.prev && (l = d.prev.index)
    } else h = !1;
    if (this.board.displayPendingMoveList(), this.board.moveArray.length > 0 && this.board.setCurrentMove(this.board.moveArray[0]), h)l > 0 && l < this.board.moveArray.length && (clog && console.log("going to currMoveIndex:" + l), this.board.gotoMoveIndex(l, !1, !0)); else {
        if (-1 == r) {
            var c = this.board.moveArray.length - 1;
            c >= 0 && this.board.gotoMoveIndex(c, !1, !0)
        } else 0 != r && this.board.gotoMoveIndex(r);
        -1 != r && this.board.autoplayFirst && this.board.forwardMove()
    }
    this.board.displayMode = !0;
    var b = this.board.boardName, u = YAHOO.util.Dom.get(b + "-whitePlayer");
    u && (u.innerHTML = o.whitePlayer);
    var g = YAHOO.util.Dom.get(b + "-blackPlayer");
    g && (g.innerHTML = o.blackPlayer);
    var p = YAHOO.util.Dom.get(b + "-event");
    p && (p.innerHTML = o.event);
    var m = YAHOO.util.Dom.get(b + "-site");
    m && (m.innerHTML = o.site);
    var v = YAHOO.util.Dom.get(b + "-date");
    v && (v.innerHTML = o.date);
    var f = YAHOO.util.Dom.get(b + "-round");
    f && (f.innerHTML = o.round);
    var P = YAHOO.util.Dom.get(b + "-whiteElo");
    P && (P.innerHTML = o.whitePlayerElo);
    var A = YAHOO.util.Dom.get(b + "-blackElo");
    A && (A.innerHTML = o.blackPlayerElo);
    var O = YAHOO.util.Dom.get(b + "-result");
    O && (O.innerHTML = o.pgn_result), clog && console.log(this.board.currentMove ? "after show game currentMove:" + this.board.currentMove.output() : "after show game currentMove is null")
};
function isMouseOver(e, t) {
    var o = YAHOO.util.Dom.get(e);
    if (!o)return !1;
    var i = YAHOO.util.Dom.getRegion(o);
    if (!i)return !1;
    {
        var s = (i.top, i.left, i.bottom, i.right, YAHOO.util.Event.getXY(t));
        s[0], s[1]
    }
}
function trimStr(e) {
    if (!e)return "";
    for (var e = e.replace(/^\s\s*/, ""), t = /\s/, o = e.length; t.test(e.charAt(--o)););
    return e.slice(0, o + 1)
}
function clearClone(e) {
    if (null != e)for (prop in e)"object" == typeof e[prop] && null != e[prop] && e[prop].alreadyCloned && (e[prop].alreadyCloned = !1, clearClone(e[prop]))
}
function cloneWork(e) {
    if (null == e)return null;
    var t = new Object;
    for (prop in e)t[prop] = "object" == typeof e[prop] ? e[prop] : e[prop];
    return t
}
function clone(e) {
    return cloneWork(e)
}
function getTagValue(e, t) {
    var o = e.getElementsByTagName(t);
    return null == o ? (YAHOO.log("got null node for tag:" + t), null) : 0 == o.length ? (YAHOO.log("got empty array node for tag:" + t), null) : null == o[0].firstChild ? (YAHOO.log("firstChild is null for tag:" + t), null) : null == o[0].firstChild.nodeValue ? (YAHOO.log("firstChild.nodeValue is null for tag:" + t), null) : "undefined" != typeof o[0].textContent ? o[0].textContent : o[0].firstChild.nodeValue
}
function unescapeHtml(e) {
    var t = document.createElement("div");
    return t.innerHTML = e, t.innerText ? t.innerText : t.textContent
}
function insertBefore(e, t) {
    t && t.parentNode.insertBefore(e, t)
}
function insertAfter(e, t) {
    var o = t.parentNode;
    o.insertBefore(e, t.nextSibling)
}
function touchHandler(e) {
    if (!(e.changedTouches && e.changedTouches.length > 1)) {
        e.preventDefault();
        var t = e.changedTouches, o = t[0], i = "";
        switch (e.type) {
            case"touchstart":
                i = "mousedown";
                break;
            case"touchmove":
                i = "mousemove";
                break;
            case"touchend":
                i = "mouseup";
                break;
            default:
                return
        }
        var s = document.createEvent("MouseEvents");
        s.initMouseEvent(i, !0, !0, window, 1, o.screenX, o.screenY, o.clientX, o.clientY, !1, !1, !1, !1, 0, null), o.target.dispatchEvent(s)
    }
}
function initIphone(e) {
    e.addEventListener("touchstart", touchHandler, !0), e.addEventListener("touchmove", touchHandler, !0), e.addEventListener("touchend", touchHandler, !0), e.addEventListener("touchcancel", touchHandler, !0)
}
var SITE_VERSION = 1, clog = !1, ctime = !1, cprof = !1, move_obj_id_counter = 0, activeBoard = null, boardSounds = new CTSound({soundPath: "/sounds"});
window.console || (window.console = {}), window.console.log || (window.console.log = function () {
}), YAHOO.util.Event.onDOMReady(function () {
    boardSounds.createSound("takesounds/78263__SuGu14__Metall01", "takePiece1"), boardSounds.createSound("movesounds/77971__SuGu14__Fusta_0_05", "movePiece3"), boardSounds.createSound("movesounds/10537__batchku__Hit_knuckle_15_004", "movePiece7"), boardSounds.createSound("analysis/76426__spazzo_1493__Finished", "finished")
}), BoardConfig = function () {
    this.boardName = "board", this.puzzle = !1, this.showToMoveIndicators = !1, this.scrollVariations = !1, this.pgnString = null, this.pgnDiv = null, this.pgnFile = null, this.scrollOffsetCorrection = 0, this.handleCommentClicks = !1, this.pollPGNMilliseconds = 0, this.pollPGNMillisecondsPostResult = 3e4, this.numberPollsAfterResult = 5, this.gotoEndOnRefresh = !1, this.allowPreMoveSelection = !1, this.pieceSet = "merida", this.pieceSize = 46, this.isEndgame = !1, this.tr = !1, this.ie6FixCoordsOffsetSize = 4, this.allIeFixCoordsOffsetSize = 0, this.addVersion = !0, this.ignoreMultipleGames = !1, this.ml = 9999, this.r = !1, this.g = !1, this.g2 = !1, this.canPasteFen = !1, this.makeActive = !1, this.showSolutionButton = !1, this.avoidMouseoverActive = !1, this.autoScrollMoves = !1, this.moveAnimationLength = .5, this.showBracketsOnVariation = !0, this.hideBracketsOnTopLevelVariation = !1, this.variationStartString = " ( ", this.variationEndString = " ) ", this.ignoreCommentRegex = null, this.newlineForEachMainMove = !0, this.useDivClearForNewline = !1, this.showNPS = !1, this.squareColorClass = "", this.analysisWindowName = "analysis_window", this.pieceTakenSize = this.pieceSize, this.pauseBetweenMoves = 800, this.pgnMode = !1, this.hidePGNErrors = !1, this.previewMode = !1, this.movesFormat = "default", this.boardImagePath = "http://chesstempo.com", this.showCoordinates = !1, this.highlightFromTo = !1, this.highlightValidSquares = !1, this.fideClock = !1, this.disableFlipper = !1, this.showResult = 1, this.showEvent = 1, this.showRound = 1, this.showSite = 1, this.showDate = 1, this.ignoreFlipping = !1, this.reverseFlip = !1, this.autoplayFirst = !1, this.dontOutputNavButtons = !1, this.dontCheckLeavingPage = !1, this.clickAndClick = !1, this.clickAndClickDisabled = !1, this.whiteMoveSoundName = "movePiece3", this.blackMoveSoundName = "movePiece7", this.whiteTakeSoundName = "takePiece1", this.blackTakeSoundName = "takePiece1", this.finishedSoundName = "finished", this.soundEnabled = !1, this.gamedb = !1
}, BoardConfig.prototype.applyConfig = function (e) {
    for (var t in e)this[t] = e[t]
}, ChessApp = function (e) {
    this.displayMode = !1, this.config = e, this.board = null
}, ChessApp.prototype.setDisplayMode = function (e) {
    this.displayMode = e
}, ChessApp.prototype.setProblemNumber = function (e, t) {
    this.problemNumber = e, this.attId = t
}, ChessApp.prototype.init = function (e, t, o, i, s) {
    function r() {
        var e = YAHOO.util.Dom.get(n.config.boardName + "-nextUpdate");
        if (e)if (n.pgn.finishedPolling || n.pgn.foundResult) {
            var t = "00", o = "00";
            e.innerHTML = '<span id="minutes">' + t + '</span>:<span id="seconds">' + o + "</span>"
        } else {
            var i = (new Date).getTime(), s = (n.pgn.lastPoll + n.pgn.pollTime - i) / 1e3;
            0 > s && (s = 0);
            var a = s, l = parseInt(a / 60), h = parseInt(a % 60);
            t = 10 > l ? "0" + l : l, o = 10 > h ? "0" + h : h, e.innerHTML = '<span id="minutes">' + t + '</span>:<span id="seconds">' + o + "</span>", setTimeout(r, 1e3)
        }
    }

    ChessPiece.init(), this.board = new Board(this.config.boardName), s && this.board.addUpdatePieceListener(i), this.board.moveArray = new Array, this.hideOnInit || (YAHOO.util.Dom.setStyle(this.config.boardName + "-container", "display", "block"), YAHOO.util.Dom.setStyle("toPlaySpan", "display", "inline")), this.tactics = this.displayMode || this.config.pgnMode || this.config.previewMode || this.config.fenBoard ? null : new TacticsUI(this.board), this.problem = this.config.pgnMode || this.config.previewMode || this.config.fenBoard ? null : new ProblemUI(this.board, this.tactics), this.board.tactics = this.tactics, this.board.problem = this.problem, this.board.puzzle = this.config.puzzle, this.problem && (this.problem.autoPlayOpponent = 1), this.pgn = this.config.pgnMode ? new PGN(this.board) : null;
    var a = MovesDisplay.DEFAULT_DISPLAY_TYPE;
    if ("main_on_own_line" == this.config.movesFormat && (a = MovesDisplay.MAIN_ON_OWN_LINE), this.movesDisplay = new MovesDisplay(this.board, a), this.movesDisplay.variationOnOwnLine = this.config.variationOnOwnLine, this.board.movesDisplay = this.movesDisplay, this.board.boardImagePath = this.config.boardImagePath, this.board.showNPS = this.config.showNPS, this.board.showSolutionButton = this.config.showSolutionButton, this.board.analysisWindowName = this.config.analysisWindowName, this.board.squareColorClass = this.config.squareColorClass, this.board.tr = this.config.tr, this.board.scrollToBoardTop = this.config.scrollToBoardTop, this.board.ml = this.config.ml, this.board.r = this.config.r, this.board.g = this.config.g, this.board.g2 = this.config.g2, this.board.canPasteFen = this.config.canPasteFen, this.board.addVersion = this.config.addVersion, this.board.ignoreMultipleGames = this.config.ignoreMultipleGames, this.board.ie6FixCoordsOffsetSize = this.config.ie6FixCoordsOffsetSize, this.board.allIeFixCoordsOffsetSize = this.config.allIeFixCoordsOffsetSize, this.board.allowingFreeMovement = this.config.allowingFreeMovement, this.board.autoScrollMoves = this.config.autoScrollMoves, this.board.moveAnimationLength = this.config.moveAnimationLength, this.board.showBracketsOnVariation = this.config.showBracketsOnVariation, this.board.hideBracketsOnTopLevelVariation = this.config.hideBracketsOnTopLevelVariation, this.board.variationStartString = this.config.variationStartString, this.board.variationEndString = this.config.variationEndString, this.board.ignoreCommentRegex = this.config.ignoreCommentRegex, this.board.newlineForEachMainMove = this.config.newlineForEachMainMove, this.board.useDivClearForNewline = this.config.useDivClearForNewline, this.board.pieceSize = this.config.pieceSize, this.board.showToMoveIndicators = this.config.showToMoveIndicators, this.board.handleCommentClicks = this.config.handleCommentClicks, this.board.scrollOffsetCorrection = this.config.scrollOffsetCorrection, this.board.pollPGNMilliseconds = this.config.pollPGNMilliseconds, this.board.pollPGNMillisecondsPostResult = this.config.pollPGNMillisecondsPostResult, this.board.numberPollsAfterResult = this.config.numberPollsAfterResult, this.board.gotoEndOnRefresh = this.config.gotoEndOnRefresh, this.board.allowPreMoveSelection = this.config.allowPreMoveSelection, this.board.pieceTakenSize = this.config.pieceTakenSize, this.board.pieceSet = this.config.pieceSet, this.board.pauseBetweenMoves = this.config.pauseBetweenMoves, this.board.showCoordinates = this.config.showCoordinates, this.board.highlightFromTo = this.config.highlightFromTo, this.board.highlightValidSquares = this.config.highlightValidSquares, this.board.fideClock = this.config.fideClock, this.board.disableFlipper = this.config.disableFlipper, this.board.showDate = this.config.showDate, this.board.showEvent = this.config.showEvent, this.board.showGame = this.config.showGame, this.board.showResult = this.config.showResult, this.board.showRound = this.config.showRound, this.board.showSite = this.config.showSite, this.board.ignoreFlipping = this.config.ignoreFlipping, this.board.reverseFlip = this.config.reverseFlip, this.board.autoplayFirst = this.config.autoplayFirst, this.board.scrollVariations = this.config.scrollVariations, this.board.dontOutputNavButtons = this.config.dontOutputNavButtons, this.board.clickAndClick = this.config.clickAndClick, this.board.clickAndClickDisabled = this.config.clickAndClickDisabled, this.board.avoidMouseoverActive = this.config.avoidMouseoverActive, this.board.dontCheckLeavingPage = this.config.dontCheckLeavingPage, this.board.whiteMoveSoundName = this.config.whiteMoveSoundName, this.board.whiteTakeSoundName = this.config.whiteTakeSoundName, this.board.blackMoveSoundName = this.config.blackMoveSoundName, this.board.blackTakeSoundName = this.config.blackTakeSoundName, this.board.soundEnabled = this.config.soundEnabled, this.board.hidePGNErrors = this.config.hidePGNErrors, this.board.gamedb = this.config.gamedb, this.config.makeActive && (activeBoard = this.board), this.problem && (this.problem.isEndgame = this.config.isEndgame), this.board.puzzle || "undefined" == typeof loginManager || (this.tactics && (loginManager.setLoginCallback(this.tactics.loginCallback, this.tactics), loginManager.setLogoutCallback(this.tactics.logoutCallback, this.tactics)), this.problem && loginManager.setSessionCallback(this.problem.sessionCallback, this.problem)), YAHOO.util.DragDropMgr.clickTimeThresh = 50, YAHOO.util.DragDropMgr.clickPixelThresh = 1, this.board.createBoardUI(), !this.board.puzzle)if (this.problem && this.problem.createProblemUI(), this.tactics && this.tactics.initProblemCompleteOverlay(), this.problem && this.problem.initLoadingOverlay(), this.config.pgnMode) {
        if (this.config.pgnFile)if (this.config.pollPGNMilliseconds) {
            this.pgn.foundResult = !1, this.pgn.foundResultPolls = 0;
            var n = this;
            this.pgn.pollTime = this.config.pollPGNMilliseconds, this.pgn.pollPGNFromURL(this.config.pgnFile, this.config.gotoEndOnRefresh, this.config.pollPGNMilliseconds), setTimeout(r, 1e3)
        } else this.pgn.getPGNFromURL(this.config.pgnFile, this.config.gotoEndOnRefresh); else if (this.config.pgnString)this.pgn.setupFromPGN(this.config.pgnString); else if (this.config.pgnDiv) {
            var l = YAHOO.util.Dom.get(this.config.pgnDiv);
            l && this.pgn.setupFromPGN(l.innerHTML)
        }
    } else if (!this.board.dontCheckLeavingPage && this.tactics)if (YAHOO.util.Event.addListener(window, "beforeunload", this.tactics.checkLeavingPage, this.tactics, !0), YAHOO.util.Event.addListener(window, "unload", this.tactics.leavingPage, this.tactics, !0), this.tactics.updateSessionDisplay(0, 0), "undefined" != typeof showingStart && showingStart) {
        var n = this, h = "";
        loggedIn && (h = this.config.isEndgame ? _js("Endgame Problem Set") + ': <span id="startProblemSetStr">' + _js(startEndgameSetName) + "</span>" : _js("Tactics Problem Set") + ': <span id="startProblemSetStr">' + _js(startTacticsSetName) + "</span>"), this.board.preloadPieces();
        {
            var c = new YAHOO.widget.SimpleDialog("starttacticdialog1", {
                width: "300px",
                fixedcenter: !0,
                modal: !1,
                visible: !0,
                draggable: !0,
                close: !1,
                text: '<div style="color:black">' + h + '</div><br/><div style="color:black">' + _js("Click start to begin solving problems") + "</div>",
                icon: YAHOO.widget.SimpleDialog.ICON_INFO,
                constraintoviewport: !0,
                buttons: [{
                    text: _js("Start"), handler: function () {
                        if (n.board.imagesLoaded)this.hide(), n.problem.getProblem(); else {
                            var e = _js("Still trying to load piece images.\n If you keep receiving this message you may need to reload the page.\n If you continue to get this message, you can disable it by going into your preferences and turning 'show problem start dialog' (available under the other tab) off.");
                            alert(e)
                        }
                    }, isDefault: !0
                }]
            });
            YAHOO.util.Dom.get("ctb-" + this.board.boardName)
        }
        c.render(document.body)
    } else this.problem.getProblem(); else this.problem && "" != this.problemNumber && (YAHOO.util.Dom.setStyle("boardandmoves", "display", "block"), this.problem.getProblem(this.problemNumber, this.attId));
    if (this.board.setupEventHandlers(), this.problem && this.problem.setupEventHandlers(), this.tactics && this.tactics.setupEventHandlers(), this.board.scrollToBoardTop) {
        var d = YAHOO.util.Dom.getXY(this.board.boardName + "-boardBorder");
        window.scrollTo(d[0], d[1])
    }
    this.config.flipListener && this.board.addFlipListener(this.config.flipListener)
}, get_image_str = function (e, t, o, i, s) {
    var r = ".vers" + SITE_VERSION;
    return s || (r = ""), check_bad_msie() ? t + "/images/" + o + "/" + e + i + r + ".png" : t + "/images/" + o + "/" + e + i + r + ".png"
}, check_bad_msie = function () {
    var e = window.ActiveXObject && "undefined" == typeof document.body.style.maxHeight;
    return e
}, fix_ie_png = function (e) {
    if (check_bad_msie()) {
        var t = e.id ? "id='" + e.id + "' " : "", o = e.className ? "class='" + e.className + "' " : "", i = e.title ? "title='" + e.title + "' " : "title='" + e.alt + "' ", s = "display:inline-block;" + e.style.cssText;
        "left" == e.align && (s = "float:left;" + s), "right" == e.align && (s = "float:right;" + s), e.parentElement.href && (s = "cursor:hand;" + s);
        var r = "<span " + t + o + i + ' style="width:' + e.width + "px; height:" + e.height + "px;" + s + ";filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src='" + e.src + "', sizingMethod='image');\"></span>";
        e.outerHTML = r
    }
}, Move = function (e, t, o, i, s, r, a) {
    this.fromColumn = e, this.fromRow = t, this.toColumn = o, this.toRow = i, this.take = s, this.promotion = r, this.moveString = a, this.prev = null, this.next = null, this.numVars = 0, this.prevMoveEnpassant = !1, this.ravLevel = 0, this.atEnd = !1, this.obj_id = move_obj_id_counter++, this.beforeComment = "", this.afterComment = ""
}, Move.prototype.freeMove = function () {
    if (this.taken && (this.taken = null), this.vars && this.vars.length > 0)for (var e = 0, e = 0; e < this.vars.length; e++)this.vars[e].freeMove()
}, Move.prototype.clone = function (e) {
    var t = this.take;
    e && t && (t = t.makeLightWeight());
    var o = new Move(this.fromColumn, this.fromRow, this.toColumn, this.toRow, t, this.promotion, this.moveString);
    if (o.moveNum = this.moveNum, o.atEnd = this.atEnd, o.beforeComment = this.beforeComment, o.afterComment = this.afterComment, o.prevMoveEnpassant = this.prevMoveEnpassant, o.index = this.index, this.vars) {
        o.vars = [];
        for (var i = 0, s = 0; s < this.vars.length; s++)o.vars[s] = this.vars[s].clone(e), i++;
        o.numVars = i
    }
    return o
}, Move.columnToChar = function (e) {
    var t = String.fromCharCode("a".charCodeAt(0) + e);
    return t
}, Move.prototype.output = function () {
    return Move.columnToChar(this.fromColumn) + "" + (this.fromRow + 1) + ":" + Move.columnToChar(this.toColumn) + (this.toRow + 1) + " prom:" + this.promotion + " objid:" + this.obj_id + " dummy:" + this.dummy + " endNode:" + this.endNode + " index:" + this.index + " moveNum:" + this.moveNum + " atEnd:" + this.atEnd + " beforeCom:" + this.beforeComment + " afterCom:" + this.afterComment
}, Move.prototype.equals = function (e) {
    return e && this.fromColumn == e.fromColumn && this.fromRow == e.fromRow && this.promotion == e.promotion && this.toColumn == e.toColumn && this.toRow == e.toRow
}, Move.moveArraysEqual = function (e, t) {
    if (e == t)return !0;
    if (null == e || null == t)return !1;
    if (e.length != t.length)return !1;
    for (var o = 0; o < e.length; o++) {
        if (!e[o].equals(t[o]))return !1;
        if (!Move.moveArraysEqual(e[o].vars, t[o].vars))return !1
    }
    return !0
}, Move.findMoveInNewArray = function (e, t, o) {
    if (e == t)return o;
    if (null == e || null == t)return null;
    if (e.length != t.length)return null;
    for (var i = 0; i < e.length; i++) {
        if (!e[i].equals(t[i]))return null;
        if (!Move.moveArraysEqual(e[i].vars, t[i].vars))return null;
        if (e[i] == o)return t[i]
    }
    return null
}, Move.prototype.toMoveString = function () {
    var e = "";
    return this.promotion && (e = this.promotion), Move.columnToChar(this.fromColumn) + "" + (this.fromRow + 1) + Move.columnToChar(this.toColumn) + (this.toRow + 1) + e
};
var ua = navigator.userAgent.toLowerCase(), isOpera = ua.indexOf("opera") > -1, isIphone = navigator.userAgent.match(/iPhone/i) || navigator.userAgent.match(/iPod/i), isIpad = navigator.userAgent.match(/iPad/i), isSafari = ua.indexOf("safari") > -1, isGecko = !isOpera && !isSafari && ua.indexOf("gecko") > -1, isIE = !isOpera && ua.indexOf("msie") > -1;
ChessPiece = function (e, t, o, i) {
    var s = e.id;
    this.board = i, this.icon = get_image_str(ChessPiece.pieceIconNames[t][o], this.board.boardImagePath, this.board.pieceSet, this.board.pieceSize, this.board.addVersion), this.colour = t, this.piece = o, this.id = s, this.div = e;
    var r = i.getPieceDragDiv(), a = !1;
    if (null == r && (r = document.createElement("div"), r.id = "pieceDragDiv", a = !0, YAHOO.util.Dom.setStyle(r, "visibility", "hidden"), YAHOO.util.Dom.setStyle(r, "border", "0px"), YAHOO.util.Dom.setStyle(r, "position", "absolute")), this.pieceDragEl = r, this.pieceDragElId = "pieceDragDiv", a) {
        var n = this.board.getDocBody();
        n && n.appendChild(r)
    }
    if (YAHOO.util.Event.isIE || isOpera) {
        var l = this.div;
        l.innerHTML = '<img src="' + this.icon + '"/>';
        var h = l.firstChild;
        fix_ie_png(h)
    } else YAHOO.util.Dom.setStyle([this.div], "backgroundImage", "url(" + this.icon + ")");
    if (YAHOO.util.Dom.setStyle([this.div], "height", this.board.pieceSize + "px"), YAHOO.util.Dom.setStyle([this.div], "width", this.board.pieceSize + "px"), YAHOO.util.Dom.setStyle([this.div], "position", "relative"), this.board.clickAndClick || (this.init(s, "ct-" + this.board.boardName + "-boardandpieces", {
            dragElId: this.pieceDragElId,
            resizeFrame: !0,
            centerFrame: !1,
            isTarget: !1
        }), this.initFrame()), (isIphone || isIpad) && this.board.clickAndClickDisabled) {
        var c = this.div, d = this;
        this.div.addEventListener("DOMNodeInserted", function (e) {
            d.touchAttached || initIphone(c), d.touchAttached = !0
        }, !1)
    }
}, ChessPiece.prototype = new YAHOO.util.DDProxy, ChessPiece.PAWN = 0, ChessPiece.BISHOP = 1, ChessPiece.KNIGHT = 2, ChessPiece.ROOK = 3, ChessPiece.KING = 4, ChessPiece.QUEEN = 5, ChessPiece.WHITE = 0, ChessPiece.BLACK = 1, ChessPiece.init = function () {
    ChessPiece.pieceIconNames = new Array(2), ChessPiece.pieceIconNames[0] = new Array(6), ChessPiece.pieceIconNames[1] = new Array(6), ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.PAWN] = "whitepawn", ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.BISHOP] = "whitebishop", ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.KNIGHT] = "whiteknight", ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.ROOK] = "whiterook", ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.KING] = "whiteking", ChessPiece.pieceIconNames[ChessPiece.WHITE][ChessPiece.QUEEN] = "whitequeen", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.PAWN] = "blackpawn", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.BISHOP] = "blackbishop", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.KNIGHT] = "blackknight", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.ROOK] = "blackrook", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.KING] = "blackking", ChessPiece.pieceIconNames[ChessPiece.BLACK][ChessPiece.QUEEN] = "blackqueen"
}, ChessPiece.materialValue = function (e) {
    switch (e) {
        case ChessPiece.PAWN:
            return 1;
        case ChessPiece.BISHOP:
            return 3;
        case ChessPiece.KNIGHT:
            return 3;
        case ChessPiece.ROOK:
            return 5;
        case ChessPiece.KING:
            return 0;
        case ChessPiece.QUEEN:
            return 9
    }
    return 0
}, ChessPiece.prototype.free = function () {
    this.board.clickAndClick || this.unreg()
}, ChessPiece.prototype.clickValidator = function (e) {
    if (this.board.dragDisabled)return !1;
    if (!this.board.allowPreMoveSelection && this.board.toMove != this.colour)return !1;
    if (-1 == this.board.restrictedColourMovement || this.colour == this.board.restrictedColourMovement) {
        var t = YAHOO.util.Event.getTarget(e), o = this.isValidHandleChild(t) && (this.id == this.handleElId || this.DDM.handleWasClicked(t, this.id));
        return this.board.selectDestSquare(e), YAHOO.util.Event.preventDefault(e), o
    }
}, ChessPiece.prototype.onDragOut = function (e, t) {
    this.insideBoard = !1
}, ChessPiece.prototype.onDragEnter = function (e, t) {
    this.insideBoard = !0
}, ChessPiece.prototype.endDrag = function (e) {
    this.board.lastOverSquare && (YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-valid-square"), YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-invalid-square")), this.board.lastOverSquare = null, this.insideBoard || (this.board.board_xy = null, this.setPosition(this.column, this.row, !1, null, this.board.moveAnimationLength)), this.hideAfterDragEnd ? this.hideAfterDragEnd = !1 : YAHOO.util.Dom.setStyle(this.getEl(), "visibility", "visible")
}, ChessPiece.prototype.startDrag = function (e, t) {
    this.insideBoard = !0;
    var o = null;
    if (o = this.board.currentMove && this.board.currentMove.prev ? this.board.currentMove.prev : this.board.prev_move, this.board.highlightValidSquares) {
        this.candidates = null, this.candidates = new Array(8);
        for (var i = 0; 8 > i; i++) {
            this.candidates[i] = new Array(8);
            for (var s = 0; 8 > s; s++)this.candidates[i][s] = !1
        }
    }
    this.pieceDragEl.innerHTML = '<img src="' + this.icon + '"/>';
    var r = this.pieceDragEl.firstChild;
    if (fix_ie_png(r), YAHOO.util.Dom.setStyle(this.pieceDragEl, "zIndex", 1e3), YAHOO.util.Dom.setStyle(this.pieceDragEl, "height", this.board.pieceSize + "px"), YAHOO.util.Dom.setStyle(this.pieceDragEl, "width", this.board.pieceSize + "px"), YAHOO.util.Dom.setStyle(this.getEl(), "visibility", "hidden"), this.board.highlightValidSquares)for (var i = 0; 8 > i; i++)for (var s = 0; 8 > s; s++) {
        var a = 7 - i, n = s;
        this.board.isFlipped && (a = 7 - a, n = 7 - n), (a == this.row && n == this.column || this.board.canMove(this.makeLightWeight(), n, a, o, !0)) && (this.candidates[s][i] = !0)
    }
}, ChessPiece.prototype.onDragOver = function (e, t) {
    var o = YAHOO.util.Event.getPageX(e), i = YAHOO.util.Event.getPageY(e), s = YAHOO.util.Dom.getX("ctb-" + this.board.boardName), r = YAHOO.util.Dom.getY("ctb-" + this.board.boardName), a = parseInt((o - s) / this.board.pieceSize), n = parseInt((i - r) / this.board.pieceSize), l = this.board.boardName + "-s" + a + (7 - n), h = YAHOO.util.Dom.get(l);
    this.board.highlightValidSquares && (this.board.lastOverSquare && this.board.lastOverSquare != h && (YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-valid-square"), YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-invalid-square"), this.board.lastOverSquare = null, this.candidates && 8 > a && a >= 0 && 8 > n && n >= 0 && this.candidates[a][n] ? YAHOO.util.Dom.addClass(h, "ct-over-valid-square") : YAHOO.util.Dom.addClass(h, "ct-over-invalid-square")), this.board.lastOverSquare = h)
}, ChessPiece.prototype.onDragDrop = function (e, t) {
    if (this.board.blockFowardBack || this.board.deferredBlockForwardBack)return !1;
    if (this.board.allowPreMoveSelection && this.board.toMove != this.colour)return !1;
    this.board.lastOverSquare && (YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-valid-square"), YAHOO.util.Dom.removeClass(this.board.lastOverSquare, "ct-over-invalid-square"));
    var o = YAHOO.util.Event.getPageX(e), i = YAHOO.util.Event.getPageY(e), s = YAHOO.util.Dom.getX("ctb-" + this.board.boardName), r = YAHOO.util.Dom.getY("ctb-" + this.board.boardName), a = parseInt((o - s) / this.board.pieceSize), n = parseInt((i - r) / this.board.pieceSize);
    if (this.board.isFlipped && (n = 7 - n, a = 7 - a), this.board.allowPreMoveSelection && this.board.boardPieces[this.column][this.row] != this)return this.setVisible(!1), this.hideAfterDragEnd = !0, !1;
    var l = !1;
    (!this.board.currentMove || this.board.currentMove.atEnd) && (l = !0), this.board.updatePiece(this, a, 7 - n, !1, !1, !0), !l && this.board.currentMove && !this.board.allowingFreeMovement && this.board.currentMove.atEnd && (this.board.toggleToMove(), this.board.updateToPlay())
}, ChessPiece.prototype.makeLightWeight = function () {
    var e = this.board.createPiece(this.colour, this.piece, !0);
    return e.column = this.column, e.row = this.row, e.enPassant = this.enPassant, e.castled = this.castled, e
}, ChessPiece.prototype.removeFromParent = function () {
    var e = this.div;
    e.parentNode && e.parentNode.removeChild(e)
}, ChessPiece.prototype.setVisible = function (e) {
    var t, o;
    e ? (o = "block", t = "visible") : (o = "none", t = "hidden"), YAHOO.util.Dom.setStyle(this.id, "visibility", t)
}, ChessPiece.prototype.moveResponse = function (e) {
}, ChessPiece.prototype.getIcon = function () {
    return this.icon
}, ChessPiece.prototype.makeHeavyWeight = function () {
    return this.copyPiece()
}, ChessPiece.prototype.copyPiece = function () {
    var e = new ChessPiece(this.div, this.colour, this.piece, this.board);
    return e.column = this.column, e.row = this.row, e.enPassant = this.enPassant, e.castled = this.castled, e
}, ChessPiece.prototype.changePieceKeepImage = function (e) {
    var t = (e + "").toLowerCase().charAt(0);
    switch (t) {
        case"k":
            this.piece = ChessPiece.KING;
            break;
        case"q":
            this.piece = ChessPiece.QUEEN;
            break;
        case"r":
            this.piece = ChessPiece.ROOK;
            break;
        case"b":
            this.piece = ChessPiece.BISHOP;
            break;
        case"n":
            this.piece = ChessPiece.KNIGHT;
            break;
        case"p":
            this.piece = ChessPiece.PAWN
    }
}, ChessPiece.prototype.changePiece = function (e) {
    if (this.changePieceKeepImage(e), this.icon = get_image_str(ChessPiece.pieceIconNames[this.colour][this.piece], this.board.boardImagePath, this.board.pieceSet, this.board.pieceSize, this.board.addVersion), YAHOO.util.Event.isIE || isOpera) {
        var t = this.div;
        t.innerHTML = '<img src="' + this.icon + '"/>';
        var o = t.firstChild;
        isOpera || fix_ie_png(o)
    } else YAHOO.util.Dom.setStyle(this.div, "backgroundImage", "url(" + this.icon + ")"), YAHOO.util.Dom.setStyle(this.div, "background-repeat", "no-repeat")
}, ChessPiece.prototype.getNewXYPosition = function (e, t) {
    var o = (this.board.getBoardDiv(), this.board.getXY()), i = o[0], s = o[1], r = [0, 0];
    return this.board.isFlipped ? (r[0] = i + (7 - e) * this.board.pieceSize, r[1] = s + t * this.board.pieceSize) : (r[0] = i + e * this.board.pieceSize, r[1] = s + (7 - t) * this.board.pieceSize), r
}, ChessPiece.prototype.setPosition = function (e, t, o, i, s, r, a) {
    if (this.column = e, this.row = t, !this.board.pieceMoveDisabled) {
        var n = this.div, l = null;
        l = this.board.isFlipped ? this.board.boardName + "-s" + (7 - this.column) + (7 - this.row) : this.board.boardName + "-s" + this.column + this.row;
        var h = this.board.getBoardDivFromId(l), c = null;
        if (c = r ? this.colour == ChessPiece.WHITE ? this.board.whiteTakeSoundName : this.board.blackTakeSoundName : this.colour == ChessPiece.WHITE ? this.board.whiteMoveSoundName : this.board.blackMoveSoundName, o) {
            var d = this.getNewXYPosition(e, t);
            this.board.oldAnim && this.board.oldAnim.isAnimated() && (this.board.oldAnim.stop(), YAHOO.util.Dom.setXY(this.board.oldAnimPieceDiv, this.board.old_new_xy, !1));
            var u = new YAHOO.util.Motion(n, {points: {to: d}});
            this.board.oldAnim = u, this.board.oldAnimPieceDiv = n, this.board.old_new_xy = d, u.duration = s;
            var v = this;
            u.onComplete.subscribe(function () {
                v.board.soundEnabled && boardSounds.playSound(c)
            }), i && u.onComplete.subscribe(i), u.animate()
        } else {
            if (this.board.settingUpPosition)n.parentNode && n.parentNode.removeChild(n), h.appendChild(n); else {
                var d = this.getNewXYPosition(e, t);
                YAHOO.util.Dom.setXY(n, d, !1)
            }
            this.setVisible(!0), a && this.board.soundEnabled && boardSounds.playSound(c), i && i()
        }
    }
}, ChessPiece.prototype.getFenLetter = function () {
    var e = ChessPiece.pieceTypeToChar(this.piece) + "";
    return this.colour != ChessPiece.WHITE && (e = e.toLowerCase()), e
}, ChessPiece.pieceTypeToChar = function (e) {
    switch (e) {
        case ChessPiece.KING:
            return "K";
        case ChessPiece.QUEEN:
            return "Q";
        case ChessPiece.ROOK:
            return "R";
        case ChessPiece.BISHOP:
            return "B";
        case ChessPiece.KNIGHT:
            return "N";
        case ChessPiece.PAWN:
            return "P"
    }
    return "?"
}, LightweightChessPiece = function (e, t, o, i) {
    this.board = i, this.colour = t, this.piece = o, this.div = e
}, LightweightChessPiece.prototype.getFenLetter = ChessPiece.prototype.getFenLetter, LightweightChessPiece.prototype.makeLightWeight = function () {
    return this.copyPiece()
}, LightweightChessPiece.prototype.makeHeavyWeight = function () {
    var e = this.board.createPiece(this.colour, this.piece, !1);
    return e.column = this.column, e.row = this.row, e.enPassant = this.enPassant, e.castled = this.castled, e
}, LightweightChessPiece.prototype.setVisible = function (e) {
}, LightweightChessPiece.prototype.free = function () {
}, LightweightChessPiece.prototype.setPosition = function (e, t, o, i, s) {
    this.column = e, this.row = t
}, LightweightChessPiece.prototype.copyPiece = function () {
    var e = new LightweightChessPiece(this.id, this.colour, this.piece, this.board);
    return e.column = this.column, e.row = this.row, e
}, LightweightChessPiece.prototype.changePiece = function (e) {
    this.changePieceKeepImage(e)
}, LightweightChessPiece.prototype.changePieceKeepImage = function (e) {
    var t = (e + "").toLowerCase().charAt(0);
    switch (t) {
        case"k":
            this.piece = ChessPiece.KING;
            break;
        case"q":
            this.piece = ChessPiece.QUEEN;
            break;
        case"r":
            this.piece = ChessPiece.ROOK;
            break;
        case"b":
            this.piece = ChessPiece.BISHOP;
            break;
        case"n":
            this.piece = ChessPiece.KNIGHT;
            break;
        case"p":
            this.piece = ChessPiece.PAWN
    }
}, MovesDisplay = function (e, t) {
    this.board = e, this.displayType = t
}, MovesDisplay.DEFAULT_DISPLAY_TYPE = 0, MovesDisplay.MAIN_ON_OWN_LINE = 1, Board = function (e) {
    this.boardName = e, e && (this.initTarget("ctb-" + e, "ct-" + this.boardName + "-boardandpieces"), this.boardPieces = Board.createBoardArray()), this.imagesLoaded = !1, this.disableNavigation = !1, this.currentMove = null, this.outputWithoutDisplay = !1, this.moveIndex = -1, this.dontUpdatePositionReachedTable = !1, this.restrictedColourMovement = -1, this.settingUpPosition = !1, this.pendingLevelZeroCommentaryClose = !1, this.isUserFlipped = !1, this.registeredFlipListeners = [], this.registeredSpaceListeners = [], this.registeredForwardAtEndListeners = [], this.registeredPasteFenClickedListeners = [], this.registeredGotoMoveIndexListeners = [], this.registeredBackMovePreCurrentListeners = [], this.registeredForwardMovePostUpdateListeners = [], this.registeredUpdateListeners = [], this.registeredUpdatePieceFinishedListeners = [], this.registeredUpdateEndOfMovesListeners = [], this.registeredUpdateHaveAltListeners = [], this.registeredUpdateWrongMoveListeners = [], this.registeredUpdateAllowMoveListeners = [], this.registeredMakeMoveListeners = [], this.moveNumber = 1, this.halfMoveNumber = 0
}, Board.prototype = new YAHOO.util.DDTarget, Board.invertToMove = function (e) {
    return e == ChessPiece.WHITE ? ChessPiece.BLACK : ChessPiece.WHITE
}, Board.boardStyleToClassName = function (e) {
    var t = "";
    switch (e) {
        case 0:
            t = "-lightgrey";
            break;
        case 1:
            t = "-grey";
            break;
        case 2:
            t = "-brown";
            break;
        case 3:
            t = "-green";
            break;
        case 4:
            t = "-woodlight";
            break;
        case 5:
            t = "-wooddark";
            break;
        case 6:
            t = "-metal";
            break;
        case 7:
            t = "-marblebrown";
            break;
        case 8:
            t = "-stucco";
            break;
        case 9:
            t = "-goldsilver";
            break;
        case 10:
            t = "-sandsnow";
            break;
        case 11:
            t = "-crackedstone";
            break;
        case 12:
            t = "-granite";
            break;
        case 13:
            t = "-marblegreen";
            break;
        case 14:
            t = "-greenwhite"
    }
    return t
}, Board.createBoardArray = function () {
    var e = boardPool.getObject();
    if (null == e) {
        e = new Array(8);
        for (var t = 0; 8 > t; t++)e[t] = new Array(8)
    }
    return e
}, Board.prototype.preloadPieces = function () {
    function e() {
        for (var o = !0, i = 0; i < t.length; i++) {
            var s = document.createElement("img");
            s.src = t[i], (!s.complete || "undefined" != typeof s.naturalWidth && 0 == s.naturalWidth) && (o = !1)
        }
        o ? r.imagesLoaded = !0 : setTimeout(e, 1e3)
    }

    for (var t = [], o = 0; o < ChessPiece.QUEEN; o++)for (var i = 0; 2 > i; i++) {
        var s = get_image_str(ChessPiece.pieceIconNames[i][o], this.boardImagePath, this.pieceSet, this.pieceSize, !0);
        t.push(s)
    }
    var r = this;
    e()
}, Board.prototype.selectDestSquare = function (e) {
    if (this.clickAndClickDisabled)return !0;
    var t = (new Date).getTime(), o = !1;
    t - this.lastDestClick < 100 && (o = !0), this.lastDestClick = t;
    var i = YAHOO.util.Event.getPageX(e), s = YAHOO.util.Event.getPageY(e), r = YAHOO.util.Dom.getX("ctb-" + this.boardName), a = YAHOO.util.Dom.getY("ctb-" + this.boardName), n = parseInt((i - r) / this.pieceSize), l = parseInt((s - a) / this.pieceSize), h = this.boardName + "-s" + n + (7 - l), c = YAHOO.util.Dom.get(h);
    if (c == this.oldSelectedSquare)return o || (YAHOO.util.Dom.removeClass(c, "ct-source-square"), this.oldSelectedSquare = null, this.oldSelectedPiece = null, this.oldDestSquare && (YAHOO.util.Dom.removeClass(this.oldDestSquare, "ct-dest-square"), this.oldDestSquare = null)), !0;
    this.isFlipped && (n = 7 - n, l = 7 - l), l = 7 - l;
    var d = this.boardPieces[n][l];
    if (!d || d.colour != this.toMove && !this.allowPreMoveSelection || -1 != this.restrictedColourMovement && d.colour != this.restrictedColourMovement) {
        if (!this.oldSelectedSquare)return !0;
        if (this.oldSelectedPiece && this.oldSelectedPiece.colour != this.toMove)return !1;
        var u = null;
        if (u = this.currentMove && this.currentMove.prev ? this.currentMove.prev : this.prev_move, this.canMove(this.oldSelectedPiece.makeLightWeight(), n, l, u, !0)) {
            this.lastDestSquare = c, this.lastDestRow = l, this.lastDestColumn = n, YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square");
            var v = !1;
            (!this.currentMove || this.currentMove.atEnd) && (v = !0), this.updatePiece(this.oldSelectedPiece, n, l, !1, !1, !0),
                this.oldSelectedPiece = null, this.oldSelectedSquare = null, !v && this.currentMove && !this.allowingFreeMovement && this.currentMove.atEnd && (this.toggleToMove(), this.updateToPlay())
        }
    } else this.oldSelectedSquare && YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square"), this.oldDestSquare && (YAHOO.util.Dom.removeClass(this.oldDestSquare, "ct-dest-square"), this.oldDestSquare = null), YAHOO.util.Dom.addClass(c, "ct-source-square"), this.oldSelectedSquare = c, this.oldSelectedPiece = d
}, Board.prototype.selectSourcePiece = function (e) {
    this.lastSourceSquare && YAHOO.util.Dom.removeClass(s, "ct-source-square");
    var t = e.row, o = e.column;
    this.isFlipped && (t = 7 - t, o = 7 - o);
    var i = this.boardName + "-s" + o + t, s = YAHOO.util.Dom.get(i);
    YAHOO.util.Dom.addClass(s, "ct-source-square"), this.lastSourceSquare = s, this.lastSourcePiece = e, this.lastSourceRow = e.row, this.lastSourceColumn = e.column
}, Board.prototype.toggleToMove = function () {
    this.toMove = this.toMove == ChessPiece.WHITE ? ChessPiece.BLACK : ChessPiece.WHITE
}, Board.prototype.setupPieceDivs = function () {
    this.getBoardDiv();
    if (this.pieces)for (var e = 0; 32 > e; e++)this.pieces[e] && (this.pieces[e].setVisible(!1), this.pieces[e].free(), this.pieces[e] = null);
    if (this.availPieceDivs)for (var e = 0; 32 > e; e++)this.availPieceDivs[e] && this.availPieceDivs[e].parentNode && this.availPieceDivs[e].parentNode.removeChild(this.availPieceDivs[e]);
    this.availids = null, this.availIds = new Array(32), this.availPieceDivs = null, this.availPieceDivs = new Array(32), this.pieces = null, this.pieces = new Array(32), this.uptoId = 0, this.uptoPiece = 0
}, Board.prototype.getXY = function () {
    return this.board_xy = YAHOO.util.Dom.getXY("ctb-" + this.boardName), this.board_xy
}, Board.prototype.updateFromTo = function (e, t, o, i, s, r) {
    YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), null != o && (this.lastFromSquare = e, this.lastToSquare = t, this.lastFromRow = o, this.lastFromColumn = i, this.lastToRow = s, this.lastToColumn = r, this.highlightFromTo && (YAHOO.util.Dom.addClass(e, "ct-from-square"), YAHOO.util.Dom.addClass(t, "ct-to-square")))
}, Board.prototype.makeMove = function (e, t, o, i, s, r, a, n, l) {
    var h, c;
    this.isFlipped ? (h = YAHOO.util.Dom.get(this.boardName + "-s" + (7 - e.fromColumn) + (7 - e.fromRow)), c = YAHOO.util.Dom.get(this.boardName + "-s" + (7 - e.toColumn) + (7 - e.toRow))) : (h = YAHOO.util.Dom.get(this.boardName + "-s" + e.fromColumn + e.fromRow), c = YAHOO.util.Dom.get(this.boardName + "-s" + e.toColumn + e.toRow)), this.oldSelectedSquare && (!this.allowPreMoveSelection || this.oldSelectedPiece && t && this.oldSelectedPiece.colour == t.colour) && (YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square"), this.oldSelectedSquare = null, this.oldSelectedPiece = null), r && this.updateFromTo(h, c, e.fromRow, e.fromColumn, e.toRow, e.toColumn);
    var d = this.boardPieces[e.toColumn][e.toRow];
    null != d && (d.enPassant = !1, d.castled = !1), t.piece == ChessPiece.PAWN && e.toColumn != e.fromColumn && null == this.boardPieces[e.toColumn][e.toRow] && (d = this.boardPieces[e.toColumn][e.fromRow], this.boardPieces[e.toColumn][e.fromRow] = null, null != d && (d.enPassant = !0));
    var u = null;
    if (t.piece == ChessPiece.KING && Math.abs(e.toColumn - e.fromColumn) > 1) {
        var v, m;
        e.toColumn > e.fromColumn ? (u = this.boardPieces[7][e.fromRow], v = e.fromRow, m = 5, this.boardPieces[7][e.toRow] = null) : (u = this.boardPieces[0][e.fromRow], v = e.fromRow, m = 3, this.boardPieces[0][e.toRow] = null), u ? (u.setPosition(m, v, o, null, i, null, l), this.boardPieces[u.column][u.row] = u, u.castled = !0) : alert("No castle piece")
    }
    e.taken = d, d && s && this.processTaken(d, !0), this.moveNumber++, e.preHalfMoveNumber = this.halfMoveNumber, this.halfMoveNumber++, (d || t.piece == ChessPiece.PAWN) && (this.halfMoveNumber = 0), this.board_xy = null, null != e.promotion && t.changePieceKeepImage(e.promotion), t.setPosition(e.toColumn, e.toRow, o, function () {
        var o = d;
        o && o.setVisible(!1), null != e.promotion && t.changePiece(e.promotion), a && a.call(n)
    }, i, d, l), o || null != e.promotion && t.changePiece(e.promotion), this.boardPieces[e.fromColumn][e.fromRow] = null, this.boardPieces[e.toColumn][e.toRow] = t, null != u && (e.taken = u), e.preCastleQueenSide = new Array(2), e.preCastleKingSide = new Array(2), e.preCastleQueenSide[0] = this.canCastleQueenSide[0], e.preCastleQueenSide[1] = this.canCastleQueenSide[1], e.preCastleKingSide[0] = this.canCastleKingSide[0], e.preCastleKingSide[1] = this.canCastleKingSide[1], t.piece == ChessPiece.ROOK ? (t.colour == ChessPiece.WHITE && 0 == e.fromRow || t.colour == ChessPiece.BLACK && 7 == e.fromRow) && (0 == e.fromColumn ? this.canCastleQueenSide[t.colour] = !1 : 7 == e.fromColumn && (this.canCastleKingSide[t.colour] = !1)) : t.piece == ChessPiece.KING && (this.canCastleQueenSide[t.colour] = !1, this.canCastleKingSide[t.colour] = !1), d && d.piece == ChessPiece.ROOK && (0 == e.toColumn ? (d.colour == ChessPiece.WHITE && 0 == e.toRow || d.colour == ChessPiece.BLACK && 7 == e.toRow) && (this.canCastleQueenSide[d.colour] = !1) : 7 == e.toColumn && (d.colour == ChessPiece.WHITE && 0 == e.toRow || d.colour == ChessPiece.BLACK && 7 == e.toRow) && (this.canCastleKingSide[d.colour] = !1)), this.updatePositionReached(t.colour);
    for (var p = 0; p < this.registeredMakeMoveListeners.length; p++) {
        this.registeredMakeMoveListeners[p].makeMoveCallback(e)
    }
}, Board.prototype.isThreeFoldRep = function (e) {
    var t = this.toMove;
    e && (t = t == ChessPiece.WHITE ? ChessPiece.BLACK : ChessPiece.WHITE);
    var o = this.boardToUniqueFen(t);
    return this.positionsSeen[o] >= 3
}, Board.prototype.updatePositionReached = function (e) {
    if (!this.dontUpdatePositionReachedTable) {
        var t = this.boardToUniqueFen(e);
        this.positionsSeen || (this.positionsSeen = []), this.positionsSeen[t] ? this.positionsSeen[t]++ : this.positionsSeen[t] = 1
    }
}, Board.prototype.promptPromotion = function (e, t, o, i, s) {
    e.prePromotionColumn = e.column, e.prePromotionRow = e.row, e.setPosition(t, o, !1, null, this.moveAnimationLength);
    var r = this, a = new YAHOO.widget.Dialog("promotionDialogId", {
        width: "300px",
        fixedcenter: !0,
        visible: !0,
        modal: !0,
        close: !1,
        constraintoviewport: !0,
        buttons: [{
            text: _js("Queen"), handler: function () {
                a.hide(), r.updatePiece(e, t, o, i, s, !1, "q")
            }, isDefault: !0
        }, {
            text: _js("Rook"), handler: function () {
                a.hide(), r.updatePiece(e, t, o, i, s, !1, "r")
            }, isDefault: !1
        }, {
            text: _js("Bishop"), handler: function () {
                a.hide(), r.updatePiece(e, t, o, i, s, !1, "b")
            }, isDefault: !1
        }, {
            text: _js("Knight"), handler: function () {
                a.hide(), r.updatePiece(e, t, o, i, s, !1, "n")
            }, isDefault: !1
        }]
    });
    a.setHeader(_js("Select Promotion Piece")), a.setBody("<div></div>"), a.render(document.body)
}, Board.moveToLocale = function (e) {
    if (!e || "" == e)return e;
    for (var t = "", o = 0; o < e.length; o++) {
        var i = e.charAt(o);
        switch (i) {
            case"K":
                i = _js("K");
                break;
            case"Q":
                i = _js("Q");
                break;
            case"R":
                i = _js("R");
                break;
            case"N":
                i = _js("N");
                break;
            case"B":
                i = _js("B");
                break;
            case"P":
                i = _js("P");
                break;
            case"a":
                i = _js("a");
                break;
            case"b":
                i = _js("b");
                break;
            case"c":
                i = _js("c");
                break;
            case"d":
                i = _js("d");
                break;
            case"e":
                i = _js("e");
                break;
            case"f":
                i = _js("f");
                break;
            case"g":
                i = _js("g");
                break;
            case"h":
                i = _js("h");
                break;
            case"x":
                i = _js("x");
                break;
            case"#":
                i = _js("#")
        }
        t += i
    }
    return t
}, Board.prototype.updatePiece = function (e, t, o, i, s, r, a, n) {
    if (a && (this.board_xy = null, e.prePromotionRow && (e.row = e.prePromotionRow, e.column = e.prePromotionColumn)), null == a && e.column == t && e.row == o)return this.board_xy = null, e.setPosition(e.column, e.row, !1, null, this.moveAnimationLength), void(clog && console.log("moved piece back to its orig position"));
    var l = null;
    if (l = this.currentMove && this.currentMove.prev ? this.currentMove.prev : this.prev_move, clog && console.log(this.currentMove ? "updatepiece currentMove:" + this.currentMove.output() : "updatepiece currentmove null"), !i && !this.canMove(e.makeLightWeight(), t, o, l, !0))return this.board_xy = null, e.setPosition(e.column, e.row, !1, null, .5), void(clog && (console.log("move not legal , move back to orig:" + this.toMove), console.log(l ? "prevMove was:" + l.output() : "prevMove was null")));
    var h = "";
    if (r && e.piece == ChessPiece.PAWN && (7 == o || 0 == o))return void this.promptPromotion(e, t, o, i, s);
    null != a && (h = a);
    var c = "";
    c += Move.columnToChar(e.column), c += String.fromCharCode("1".charCodeAt(0) + e.row), c += Move.columnToChar(t), c += String.fromCharCode("1".charCodeAt(0) + o), h && (c += h);
    var d = this.createMoveFromString(c), u = this.currentMove;
    u && (d.moveNum = u.moveNum);
    for (var v = null, m = 0; m < this.registeredUpdateListeners.length; m++) {
        if (g = this.registeredUpdateListeners[m].updatePieceCallback(h, e, t, o, i, s, r, a, n, l, this.currentMove, d), !g)return !1;
        g.ignoreRetVal || (v = g)
    }
    if (!v)return clog && console.log("Got no update piece callbak"), !1;
    if (v.allowMove) {
        this.oldSelectedSquare && YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square");
        for (var u = v.move, m = 0; m < this.registeredUpdateAllowMoveListeners.length; m++) {
            this.registeredUpdateAllowMoveListeners[m].updateAllowMoveCallback(h, e, t, o, i, s, r, a, n, u)
        }
        this.makeMove(u, e, s, this.moveAnimationLength, !0, !0, null, null, !0);
        var p = !v.dontMakeOpponentMove && !i && this.currentMove && this.currentMove.next && !this.currentMove.next.atEnd;
        if (clog && console.log(u.next ? "setting current move in updatepiece to:" + u.next.output() : "in updatepiece, current move being set to null"), this.setCurrentMove(u.next, !1, p), this.currentMove.atEnd)for (var m = 0; m < this.registeredUpdateEndOfMovesListeners.length; m++)var v = this.registeredUpdateEndOfMovesListeners[m].updateEndOfMovesCallback(h, e, t, o, i, s, r, a, n);
        p && (opponentMove = this.currentMove, this.currentMove && this.currentMove.next.atEnd && this.toggleToMove(), this.updatePiece(this.boardPieces[opponentMove.fromColumn][opponentMove.fromRow], opponentMove.toColumn, opponentMove.toRow, !0, !0, !1))
    } else {
        {
            var u = v.move;
            e.column, e.row
        }
        this.board_xy = null, e.setPosition(e.column, e.row, !1, null, this.moveAnimationLength);
        for (var m = 0; m < this.registeredUpdateWrongMoveListeners.length; m++)var v = this.registeredUpdateWrongMoveListeners[m].updateWrongMoveCallback(h, e, t, o, i, s, r, a, n, u)
    }
    for (var m = 0; m < this.registeredUpdatePieceFinishedListeners.length; m++)var g = this.registeredUpdatePieceFinishedListeners[m].updatePieceFinishedCallback(h, e, t, o, i, s, r, a, n, l, this.currentMove, d)
}, Board.prototype.addGotoMoveIndexListener = function (e) {
    this.registeredGotoMoveIndexListeners.push(e)
}, Board.prototype.addPasteFenClickedListener = function (e) {
    this.registeredPasteFenClickedListeners.push(e)
}, Board.prototype.addBackMovePreCurrentListener = function (e) {
    this.registeredBackMovePreCurrentListeners.push(e)
}, Board.prototype.addForwardMovePostUpdateListener = function (e) {
    this.registeredForwardMovePostUpdateListeners.push(e)
}, Board.prototype.addForwardAtEndListener = function (e) {
    this.registeredForwardAtEndListeners.push(e)
}, Board.prototype.addUpdatePieceListener = function (e) {
    this.registeredUpdateListeners.push(e)
}, Board.prototype.addUpdatePieceFinishedListener = function (e) {
    this.registeredUpdatePieceFinishedListeners.push(e)
}, Board.prototype.addUpdatePieceEndOfMovesListener = function (e) {
    this.registeredUpdateEndOfMovesListeners.push(e)
}, Board.prototype.addUpdatePieceHaveAltListener = function (e) {
    this.registeredUpdateHaveAltListeners.push(e)
}, Board.prototype.addUpdatePieceAllowMoveListener = function (e) {
    this.registeredUpdateAllowMoveListeners.push(e)
}, Board.prototype.addMakeMoveListener = function (e) {
    this.registeredMakeMoveListeners.push(e)
}, Board.prototype.addUpdatePieceWrongMoveListener = function (e) {
    this.registeredUpdateWrongMoveListeners.push(e)
}, Board.prototype.scoreToShortString = function (e) {
    return "draw" == e ? "D" : e >= 0 ? "M" + e : "L" + -1 * e
}, Board.prototype.scoreToLongString = function (e) {
    return "draw" == e ? _js("Draw") : 0 == e ? _js("Mate") : e > 0 ? __js("Mate in {NUMBER_MOVES}", [["NUMBER_MOVES", e]]) : __js("Lose in {NUMBER_MOVES}", [["NUMBER_MOVES", -1 * e]])
}, Board.prototype.egMoveToScoreString = function (e) {
    var t = e.score, o = e.optimal_score, i = this.scoreToShortString(t), s = this.scoreToShortString(o), r = this.scoreToLongString(t), a = this.scoreToLongString(o);
    if (t == o)return ["", r];
    var n = "ct-subopt-move-score";
    return ("draw" == t || 0 > t) && (n = "ct-bad-move-score"), ['<span class="' + n + '">' + i + "(" + s + ")</span>", r + "(" + a + ")"]
}, Board.prototype.makeShortAlgabraic = function (e, t, o, i, s) {
    clog && console.log("fromCol:" + e + " fromRow:" + t + " toCol:" + o + " toRow:" + i);
    var r = this.boardPieces[e][t], a = r.piece, n = ChessPiece.pieceTypeToChar(a), l = "";
    if (a == ChessPiece.PAWN)e == o ? l = Move.columnToChar(e) + "" + (i + 1) : (l = Move.columnToChar(e) + "x" + Move.columnToChar(o) + (i + 1), this.boardPieces[o][i] || (l += " e.p.")); else if (a == ChessPiece.KING) {
        var h = Math.abs(e - o);
        1 == h || 0 == h ? (l = n, this.boardPieces[o][i] && (l += "x"), l += Move.columnToChar(o) + "" + (i + 1)) : l = 6 == o ? "O-O" : "O-O-O"
    } else {
        for (var c = [], d = 0; 8 > d; d++)for (var u = 0; 8 > u; u++) {
            var v = this.boardPieces[u][d];
            if (v && v.colour == r.colour && v.piece == a && (r.column != v.column || r.row != v.row)) {
                var m = null;
                this.currentMove && (m = this.currentMove.prev), this.canMove(v.makeLightWeight(), o, i, m, !0) && c.push(v)
            }
        }
        if (l = n, c.length > 0) {
            for (var p = !1, g = !1, f = 0; f < c.length; f++)c[f].row == t && (g = !0), c[f].column == e && (p = !0);
            (g || !g && !p) && (l += Move.columnToChar(e)), p && (l += "" + (t + 1))
        }
        this.boardPieces[o][i] && (l += "x"), l += Move.columnToChar(o) + "" + (i + 1)
    }
    var b = "", C = "";
    if (s) {
        var y = this.cloneBoard(), M = ChessPiece.WHITE;
        y.boardPieces[s.fromColumn][s.fromRow].colour == ChessPiece.WHITE && (M = ChessPiece.BLACK), y.makeMove(s, y.boardPieces[s.fromColumn][s.fromRow], !1, y.moveAnimationLength, !1, !1), y.isKingSafe(M, s) || (b = "+", y.isKingMated(M, s) && (b = "#")), s.promotion && (C = "=" + (s.promotion + "").toUpperCase())
    }
    return l += C + b
}, Board.getVarMove = function (e, t, o, i, s) {
    if (e.vars && e.vars.length > 0)for (var r = 0, r = 0; r < e.vars.length; r++) {
        var a = e.vars[r];
        if (a.fromColumn == i.column && a.fromRow == i.row && a.toRow == t && a.toColumn == o && ("" == s || s == a.promotion))return a
    }
}, Board.prototype.createMoveFromString = function (e) {
    var t = 0, o = !1, i = null, s = e.charCodeAt(t++), r = e.charCodeAt(t++), a = e.split("|"), n = null;
    a.length > 1 ? (n = a[1], e = a[0]) : e = a[0], "x" == e.charAt(t) && (t++, o = !0);
    var l = e.charCodeAt(t++), h = e.charCodeAt(t++);
    t < e.length && (i = e.charAt(t));
    var c = new Move(s - "a".charCodeAt(0), r - "1".charCodeAt(0), l - "a".charCodeAt(0), h - "1".charCodeAt(0), o, i, e);
    return c.pgn = n, c
}, Board.prototype.getBackButton = function () {
    return this.backButton || (this.backButton = YAHOO.util.Dom.get(this.boardName + "-back")), this.backButton
}, Board.prototype.getForwardButton = function () {
    return this.forwardButton || (this.forwardButton = YAHOO.util.Dom.get(this.boardName + "-forward")), this.forwardButton
}, Board.prototype.getEndButton = function () {
    return this.endButton || (this.endButton = YAHOO.util.Dom.get(this.boardName + "-end")), this.endButton
}, Board.prototype.getStartButton = function () {
    return this.startButton || (this.startButton = YAHOO.util.Dom.get(this.boardName + "-start")), this.startButton
}, Board.prototype.setForwardBack = function () {
    var e = this.getBackButton(), t = this.getForwardButton(), o = this.getEndButton(), i = this.getStartButton();
    return this.currentMove ? (null == this.currentMove.prev ? (e && (e.src = this.boardImagePath + "/images/resultset_previous_disabled" + this.getVersString() + ".gif"), i && (i.src = this.boardImagePath + "/images/disabled_resultset_first" + this.getVersString() + ".gif")) : (e && (e.src = this.boardImagePath + "/images/resultset_previous" + this.getVersString() + ".gif"), i && (i.src = this.boardImagePath + "/images/resultset_first" + this.getVersString() + ".gif")), void(this.currentMove.atEnd ? (t && (t.src = this.boardImagePath + "/images/resultset_next_disabled" + this.getVersString() + ".gif"), o && (o.src = this.boardImagePath + "/images/disabled_resultset_last" + this.getVersString() + ".gif")) : (t && (t.src = this.boardImagePath + "/images/resultset_next" + this.getVersString() + ".gif"), o && (o.src = this.boardImagePath + "/images/resultset_last" + this.getVersString() + ".gif")))) : (e && (e.src = this.boardImagePath + "/images/resultset_previous_disabled" + this.getVersString() + ".gif"), i && (i.src = this.boardImagePath + "/images/disabled_resultset_first" + this.getVersString() + ".gif"), t && (t.src = this.boardImagePath + "/images/resultset_next_disabled" + this.getVersString() + ".gif"), void(o && (o.src = this.boardImagePath + "/images/disabled_resultset_last" + this.getVersString() + ".gif")))
}, Board.prototype.convertPiecesFromLightWeight = function (e) {
    var t = this.settingUpPosition;
    this.settingUpPosition = !0;
    for (var o = 0; 8 > o; o++)for (var i = 0; 8 > i; i++)if (null != this.boardPieces[o][i]) {
        var s = this.boardPieces[o][i], r = s.makeHeavyWeight();
        this.boardPieces[o][i] = r, r.setPosition(r.column, r.row, !1, null, this.moveAnimationLength), r.setVisible(!0)
    }
    for (var a = this.moveArray[e]; null != a;)a.taken && (a.taken = a.taken.makeHeavyWeight()), a = a.prev;
    this.settingUpPosition = t
}, MovesDisplay.prototype.setToMove = function (e) {
    this.toMove = e
}, MovesDisplay.prototype.clickComment = function (e) {
    var t = e.currentTarget ? e.currentTarget : e.targetElement ? e.targetElement : !1;
    t || (t = YAHOO.util.Event.getTarget(e)), t.id || (t = t.parentNode);
    var o = t.id.substr((this.board.boardName + "-mcX").length), i = !0;
    t.id.indexOf("-mca") >= 0 && (i = !1);
    var s = this.board.moveArray[o], r = "";
    r = i ? s.beforeComment : s.afterComment, mySimpleDialog = new YAHOO.widget.SimpleDialog(this.boardName + "-editCommentDialog", {
        width: "20em",
        fixedcenter: !0,
        modal: !0,
        visible: !1,
        draggable: !1
    }), mySimpleDialog.setHeader("Edit Comment"), mySimpleDialog.setBody('<textarea id="' + this.board.boardName + '-editComment">' + r + "</textarea>"), mySimpleDialog.cfg.setProperty("icon", YAHOO.widget.SimpleDialog.ICON_INFO);
    var a = this, n = function () {
        i ? s.beforeComment = null : s.afterComment = null, t.innerHTML = "", this.hide()
    }, l = function () {
        var e = YAHOO.util.Dom.get(a.board.boardName + "-editComment"), o = trimStr(e.value);
        i ? s.beforeComment = o : s.afterComment = o, t.innerHTML = i ? a.outputComment(o, 0) + " " : " " + a.outputComment(o, 0), this.hide()
    }, h = function () {
        this.hide()
    }, c = [{text: "Delete", handler: n}, {text: "Save", handler: l}, {text: "Cancel", handler: h, isDefault: !0}];
    mySimpleDialog.cfg.queueProperty("buttons", c), mySimpleDialog.render(document.body), mySimpleDialog.show()
}, MovesDisplay.prototype.gotoMove = function (e) {
    if (!this.board.disableNavigation && !(this.board.tactics && this.board.tactics.problemActive || this.board.blockFowardBack || this.board.deferredBlockForwardBack)) {
        activeBoard = this.board;
        var t = e.currentTarget ? e.currentTarget : e.targetElement ? e.targetElement : !1;
        t || (t = YAHOO.util.Event.getTarget(e)), t.id || (t = t.parentNode);
        var o = t.id.substr((this.board.boardName + "-m").length);
        clog && console.log("got goto move index:" + o), this.board.gotoMoveIndex(o, !1, !1, !1, !1), this.board.problem && (this.board.currentMove.bestMoves ? this.board.problem.showBestMoves(this.board.currentMove, this.board.currentMove.bestMoves, this.board.currentMove.correctMove, this.board.currentMove.wrongMove) : this.board.problem.clearBestMoves())
    }
}, MovesDisplay.prototype.getMovesDisplay = function () {
    if (!this.cachedMovesDisplay && !this.allreadyCachedMovesDisplay) {
        var e = this.board.boardName + "-moves";
        this.moveListName && (e = this.moveListName), this.cachedMovesDisplay = YAHOO.util.Dom.get(e), this.allreadyCachedMovesDisplay = !0
    }
    return this.cachedMovesDisplay
}, MovesDisplay.prototype.outputVariationStart = function (e, t, o, i) {
    var s = "";
    if (t > this.board.ml)return s;
    if (1 == this.board.ml && i > 1)return s;
    var r = this.getMovesDisplay();
    return (r || this.board.outputWithoutDisplay) && (0 == e && this.displayType == MovesDisplay.MAIN_ON_OWN_LINE && this.firstNonMove && (this.board.useDivClearForNewline && (s += '<div style="clear:both;"></div>'), s += '<div class="ct-mainline-commentary"/>', this.pendingLevelZeroCommentaryClose = !0), this.variationOnOwnLine && (s += this.board.useDivClearForNewline ? '<div style="clear:both;"></div>' : "<br/>"), this.board.showBracketsOnVariation && (!this.board.hideBracketsOnTopLevelVariation || e > 0) && (s += "<span>" + this.board.variationStartString + "</span>")), this.firstNonMove = !1, s
}, MovesDisplay.prototype.outputVariationEnd = function (e, t, o, i) {
    var s = this.getMovesDisplay(), r = "";
    return 1 == this.board.ml && t > 0 && this.board.outputFirstVar ? r : (this.board.outputFirstVar = !0, (s || this.board.outputWithoutDisplay) && this.board.showBracketsOnVariation && (!this.board.hideBracketsOnTopLevelVariation || e > 1) && (r += "<span>" + this.board.variationEndString + "</span>"), 1 == e && this.displayType == MovesDisplay.MAIN_ON_OWN_LINE, this.firstNonMove = !1, r)
}, MovesDisplay.prototype.outputComment = function (e, t, o, i) {
    if (this.board.ignoreCommentRegex) {
        var s = new RegExp(this.board.ignoreCommentRegex);
        if (s.test(e))return ""
    }
    var r = "";
    if (1 == this.board.ml)return r;
    var a = this.getMovesDisplay();
    if (a || this.board.outputWithoutDisplay) {
        0 == t && this.displayType == MovesDisplay.MAIN_ON_OWN_LINE && (this.firstNonMove && (r += "<br/>"), r += '<div class="ct-mainline-commentary">', this.pendingLevelZeroCommentaryClose = !0);
        var n = "ct-board-move-comment";
        o && (n = "ct-board-move-alt-comment"), this.board.handleCommentClicks && (n += " ct-board-clickable-comment"), r += '<span class="' + n + '"> ' + e + " </span>", 0 == t && this.displayType == MovesDisplay.MAIN_ON_OWN_LINE
    }
    return i || (this.firstNonMove = !1), r
}, MovesDisplay.prototype.outputNag = function (e) {
    var t = "", o = this.getMovesDisplay();
    if (o || this.board.outputWithoutDisplay) {
        var i = null;
        switch (e) {
            case 11:
                i = "=";
                break;
            case 14:
                i = "+=";
                break;
            case 15:
                i = "=+";
                break;
            case 16:
                i = "+/-";
                break;
            case 17:
                i = "-/+";
                break;
            case 18:
                i = "+-";
                break;
            case 19:
                i = "-+";
                break;
            case 20:
                i = "+--";
                break;
            case 21:
                i = "--+"
        }
        i && (t += "<span> " + i + " </span>")
    }
    return t
}, MovesDisplay.prototype.outputResult = function (e) {
    return '<span class="ct-result">' + e + "</span>"
}, MovesDisplay.prototype.outputMove = function (e, t, o, i, s, r, a, n, l, h, c, d, u, v, m) {
    var p = !1;
    p && console.log("outputMove:" + i + " hideScore:" + l + " this.board:" + this.board);
    var g = "", f = this.getMovesDisplay();
    if (this.board.tr && t > 0 && (r > 1 || a > 3) && !s)return g;
    if (p && console.log("ravLevel:" + t + " ravCount:" + r + " topCount:" + a + " output:" + i), 1 == this.board.ml && r > 0 && this.board.outputFirstVar)return g;
    if (p && console.log("movesDisplay:" + f), f || this.board.outputWithoutDisplay) {
        var b = "" + Math.round(o / 2) + ". ", C = !1;
        o % 2 != 1 && (p && console.log("firstRav:" + s + " firstNonMove:" + this.firstNonMove), s || !this.firstNonMove ? (b = Math.round(o / 2) + "... ", C = !0) : b = ""), p && console.log("moveNum:" + o + " moveNumOut:" + b), this.displayType != MovesDisplay.MAIN_ON_OWN_LINE || 0 != t || this.firstNonMove && o % 2 != 1 || (this.pendingLevelZeroCommentaryClose && (this.pendingLevelZeroCommentaryClose = !1, g += "</div>"), this.board.newlineForEachMainMove && (g += this.board.useDivClearForNewline ? '<div style="clear:both;"></div>' : "<br/>"));
        var y = "", M = "";
        if (n && n.eg_move) {
            var O = this.board.egMoveToScoreString(n.eg_move);
            y = O[0], M = O[1]
        }
        var P = "";
        l && (P = "initially_hidden"), "" != y && (y = " " + y);
        var A = "title";
        l && (A = "alt");
        var S = "";
        h && (S = ' rel="' + i + '" ', i = "___");
        var w = "";
        C && 0 == t && (w = '<span class="ct-board-move-dottedempty">&nbsp;</span>');
        var N = "";
        b && (N = '<span class="ct-board-move-movenum">' + b + "</span>");
        var D = "";
        0 == e && (D = c ? " ct-best-move " : u ? " ct-bad-move " : d ? " ct-good-move " : v ? " ct-current-move " : " ct-first-move "), m && (D = " ct-current-move "), g += "<span " + S + A + '="' + M + '" id="' + this.board.boardName + "-m" + e + '" class="' + (0 == t ? "ct-board-move-mainline" : "ct-board-move-variation") + D + '">' + N + w + '<span class="ct-board-move-movetext">' + i + '</span><span id="' + this.board.boardName + "-msc" + e + '" class="' + P + '">' + y + "</span></span>"
    }
    return this.firstNonMove = !0, g
}, Board.prototype.setMoveSeqLalg = function (e, t, o, i, s, r, a, n, l, h, c, d) {
    var u = new Array;
    e && e.length > 0 && (u = e.replace(/\s+$/g, "").split(" ")), this.setupFromLalgArray(u, i, o, t, s, r, a, n, l, h, c, d)
}, Board.prototype.setupFromLalgArray = function (e, t, o, i, s, r, a, n, l, h, c, d) {
    var u = !1;
    if (u && console.log("top of setupFromLalgArray"), this.outputFirstVar = !1, this.movesDisplay) {
        this.movesDisplay.pendingLevelZeroCommentaryClose = !1;
        var v = this.movesDisplay.getMovesDisplay();
        v && (r || YAHOO.util.Event.purgeElement(v, !0), v.innerHTML = "")
    }
    i || (i = new Array);
    var m = this.cloneBoard();
    this.movesDisplay.firstNonMove = !1;
    var p = null, g = null;
    s || (p = new Array, g = new Array), !h && this.prev_move && (u && console.log("this.prev_move:" + this.prev_move.output()), m.boardPieces[this.prev_move.fromColumn][this.prev_move.fromRow] && m.makeMove(this.prev_move, m.boardPieces[this.prev_move.fromColumn][this.prev_move.fromRow], !1, m.moveAnimationLength, !1, !1));
    var f = null;
    s || (f = m.cloneBoard());
    var b = null, C = 0, y = "", M = !1, O = !1, P = 0, A = !1, S = new Array, w = new Array;
    w[0] = 0;
    for (var N = new Array, D = new Array, k = 2 * o - 1, B = 2 * o - 1, H = new Array, E = ChessPiece.WHITE, x = 0, L = "", I = "", T = "", F = "", Y = -1, _ = 0, R = 0; R < e.length; R++) {
        var q = 0;
        if (u && console.log("movesArr[" + R + "]:" + e[R]), "ALT" != e[R])if (0 != e[R].indexOf("EVAL"))if (0 != e[R].indexOf("DEPTH"))if (0 != e[R].indexOf("NODES")) {
            if (0 == e[R].indexOf("TIME")) {
                F = e[R].split(":")[1];
                var K = L;
                if (0 != L.indexOf("mate"))K = (parseFloat(L) / 100).toFixed(2), K > 0 && (K = "+" + K); else {
                    K = K.replace(/_/, " ");
                    var V = K.split(" ");
                    q = parseInt(V[1]), K = _js("mate") + " " + V[1], 1 == w[P] && (Y = q)
                }
                _ = q, 0 > q ? O = !1 : q > 0 && 8 > q && P > 0 && w[P] > 1 && (O = !0);
                var W = "";
                O && (W = _js("ALT") + " ");
                var z = (parseInt(F), " " + __js("nps:{NODES_PER_SECOND}", [["NODES_PER_SECOND", Math.round(parseInt(T) / (parseInt(F) / 1e3))]]));
                this.showNPS || (z = ""), e[R] = P > 0 && w[P] > this.ml ? "" : W + K + " (" + __js("depth:{DEPTH}", [["DEPTH", I]]) + z + ")"
            }
            if ("}" != e[R])if (M)y += e[R] + " "; else if ("{" != e[R])if ("(" != e[R])if (")" != e[R])if ("$" != e[R].charAt(0)) {
                var j = this.createMoveFromString(e[R]), G = !1;
                k == B && this.boardPieces[j.fromColumn][j.fromRow].colour == ChessPiece.BLACK && (k++, G = !0, E = ChessPiece.BLACK), j.index = C;
                var U = j.pgn ? j.pgn : j.moveString;
                if (j.pgn ? U = j.pgn : (U = m.makeShortAlgabraic(j.fromColumn, j.fromRow, j.toColumn, j.toRow, j), j.SAN = U), U = Board.moveToLocale(U), this.movesDisplay) {
                    this.movesDisplay.setToMove(E);
                    var Q = !1;
                    if (c && d && !d.atEnd) {
                        var X = d.toMoveString();
                        d = d.next, X == e[R] ? Q = !0 : c = !1
                    }
                    H.push(this.movesDisplay.outputMove(C, P, k, U + " ", A, w[P], S[0], null, !1, !1, a, n, l, c, Q))
                }
                if (E = E == ChessPiece.BLACK ? ChessPiece.WHITE : ChessPiece.BLACK, j.moveNum = k, k++, P > 0)if (A) {
                    var Z = b;
                    null == Z && alert("Got no previous move for variation:" + movesArra[R]), 0 == Z.numVars && (Z.vars = new Array), j.isAlt = O, j.mateInMoves = _, Z.vars[Z.numVars++] = j, j.prev = Z.prev, A = !1
                } else j.prev = b, null != b && (b.next = j); else j.prev = b, null != b && (b.next = j);
                w[P + 1] = 0, 0 == P && (x = C), i[C++] = j, m.moveArray[C - 1] = j, b = j, s || (f = m.cloneBoard()), m.makeMove(j, m.boardPieces[j.fromColumn][j.fromRow], !1, m.moveAnimationLength, !1, !1)
            } else this.movesDisplay && H.push(this.movesDisplay.outputNag(parseInt(e[R].substring(1)))); else {
                this.movesDisplay && H.push(this.movesDisplay.outputVariationEnd(P, w[P], k, S[0]));
                var $ = new Move;
                $.atEnd = !0, b.next = $, $.prev = b, P--, k = S[P], b = N[P], E = D[P], m = p[P], f = g[P], O = !1
            } else w[P + 1] || (w[P + 1] = 0), w[P + 1]++, this.movesDisplay && H.push(this.movesDisplay.outputVariationStart(P, w[P + 1], k, S[0])), S[P] = k, N[P] = b, D[P] = E, p[P] = m, g[P] = f, m = f.cloneBoard(), P++, k--, A = !0; else y = "", M = !0; else M = !1, this.movesDisplay && (y = y.replace(/\s+$/g, ""), H.push(this.movesDisplay.outputComment(y, P, O)))
        } else T = e[R].split(":")[1]; else I = e[R].split(":")[1]; else L = e[R].split(":")[1], parseInt(L) >= 175 && P > 0 && w[P] > 1 && (O = !0); else O = !0
    }
    if (this.movesDisplay && !this.disableMoveOutput) {
        {
            this.movesDisplay.getMovesDisplay()
        }
        H.push(this.movesDisplay.outputResult(t)), this.pendingMovesOutput = H.join(""), this.pendingMovesOutputCount = C
    }
    if (this.lastMoveIndex = x, null != b) {
        var $ = new Move;
        $.atEnd = !0, b.next = $, $.prev = b
    }
    this.lastCount = C
}, Board.prototype.getMaterialCount = function () {
    for (var e = 0, t = 0, o = 0; 8 > o; o++)for (var i = 0; 8 > i; i++) {
        var s = this.boardPieces[o][i];
        s && (s.colour == ChessPiece.WHITE ? e += ChessPiece.materialValue(s.piece) : t += ChessPiece.materialValue(s.piece))
    }
    return [e, t]
},Board.prototype.getMaterialBalance = function () {
    var e = this.getMaterialCount();
    return e[0] - e[1]
},Board.prototype.getMaterialBalances = function () {
    var e = this.cloneBoard(), t = this.moveArray[0];
    e.gotoMoveIndex(-1, !0, !0, !0, !0);
    for (var o = []; t && !t.atEnd;)e.makeMove(t, e.boardPieces[t.fromColumn][t.fromRow], !1, this.moveAnimationLength, !1, !1), o.push(e.getMaterialBalance()), t = t.next, e.toggleToMove();
    return o
},Board.prototype.lalgToMoveList = function (e, t, o, i, s, r) {
    ctime && console.time("lalgToMoveList"), clog && console.log("startMoveNum:" + o), i || (i = new Array);
    var a = this.cloneBoard(), n = null, l = null;
    r || (n = new Array, l = new Array), !s && this.prev_move && a.makeMove(this.prev_move, a.boardPieces[this.prev_move.fromColumn][this.prev_move.fromRow], !1, a.moveAnimationLength, !1, !1);
    var h = null;
    r || (h = a.cloneBoard());
    var c = [], d = null, u = 0, v = "", m = !1, p = 0, g = !1, f = new Array, b = new Array;
    b[0] = 0;
    for (var C = new Array, y = new Array, M = 2 * o - 1, O = (new Array, ChessPiece.WHITE), P = 0, A = !0, S = 0; S < e.length; S++)if ("}" != e[S])if (m)v += e[S] + " "; else if ("{" != e[S])if ("(" != e[S])if (")" != e[S])if ("$" != e[S].charAt(0)) {
        var w = this.createMoveFromString(e[S]);
        w.nags = c, w.beforeComment = trimStr(v), v = null, c = [], A && (this.boardPieces[w.fromColumn][w.fromRow].colour == ChessPiece.BLACK && (M++, O = ChessPiece.BLACK, clog && console.log("first move black new movenum:" + M)), A = !1), w.index = u;
        var N = w.pgn ? w.pgn : w.moveString;
        if (w.pgn ? (N = w.pgn, w.SAN = w.pgn) : (N = a.makeShortAlgabraic(w.fromColumn, w.fromRow, w.toColumn, w.toRow, w), w.SAN = N), O = O == ChessPiece.BLACK ? ChessPiece.WHITE : ChessPiece.BLACK, w.moveNum = M, M++, p > 0)if (g) {
            var D = d;
            null == D && alert("Got no previous move for variation:" + movesArra[S]), 0 == D.numVars && (D.vars = new Array), D.vars[D.numVars++] = w, w.prev = D.prev, g = !1
        } else w.prev = d, null != d && (d.next = w); else w.prev = d, null != d && (d.next = w);
        b[p + 1] = 0, 0 == p && (P = u), i[u++] = w, a.moveArray[u - 1] = w, d = w, r || (h = a.cloneBoard()), a.makeMove(w, a.boardPieces[w.fromColumn][w.fromRow], !1, a.moveAnimationLength, !1, !1)
    } else c.push(parseInt(e[S].substring(1))); else {
        d && (clog && (console.log("var end comment:" + v), console.log("var end comment:" + d.output())), d.afterComment = trimStr(v), v = "");
        var k = new Move;
        k.atEnd = !0, d.next = k, k.prev = d, p--, M = f[p], d = C[p], O = y[p], a = n[p], h = l[p]
    } else clog && console.log("var start comment:" + v), d && (d.afterComment = trimStr(v), v = ""), clog && console.log(d ? "old:" + d.output() : "no old move"), b[p + 1] || (b[p + 1] = 0), b[p + 1]++, f[p] = M, C[p] = d, y[p] = O, n[p] = a, l[p] = h, a = h.cloneBoard(), p++, M--, g = !0; else v && d && (d.afterComment = trimStr(v)), v = "", m = !0; else m = !1, v = v.replace(/\s+$/g, "");
    if (null != d) {
        var k = new Move;
        k.atEnd = !0, d.next = k, k.prev = d, v && (d.afterComment = trimStr(v))
    }
    return ctime && console.timeEnd("lalgToMoveList"), i
},Board.prototype.reset = function (e, t) {
    this.lastFromSquare && YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), this.lastToSquare && YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), this.clearMoveList(), e ? (this.startFen = e, this.setupFromFen(e, !1, this.isFlipped, !1, t, !0)) : (this.startFen = Board.INITIAL_FEN, this.setupFromFen(Board.INITIAL_FEN, !1, this.isFlipped, !1, !1, !0)), this.setForwardBack()
},Board.prototype.clearMoveList = function (e) {
    this.movesDisplay.firstNonMove = !1;
    var t = this.movesDisplay.getMovesDisplay();
    t && (YAHOO.util.Event.purgeElement(t, !0), t.innerHTML = ""), this.currentMove = null, this.moveIndex = -1, this.moveArray = new Array, e ? (e.prev = null, this.startMoveNum = e.moveNum) : this.startMoveNum = 1
},Board.prototype.insertMovesFromMoveList = function (e, t, o, i, s) {
    var r = !t;
    if (clog && console.log("insertMovesFromMoveList called"), ctime && r && console.time("insertMovesFromMoveList"), this.movesDisplay) {
        r && this.clearMoveList(e);
        for (var a = 0, n = (e.moveNum, e); null != n && !n.atEnd;) {
            clog && console.log("move:" + n.output());
            var l = n.next;
            if (clog && (console.log(this.currentMove ? "current move:" + this.currentMove.output() : "no current move"), console.log(l ? "next move:" + l.output() : "no next move")), r || e != n || null == o ? (clog && console.log("about to call insertmoveafter"), null != i ? (clog && console.log("inserting after moveToInsertAfter:" + i.output()), this.insertMoveAfter(i, n), i = null) : (clog && console.log("inserting after current move"), this.insertMoveAfter(this.currentMove, n)), clog && console.log("finished call to insertmoveafter")) : (clog && console.log("about to replace variationParent:" + o.output() + " with move:" + n.output() + " and board:" + this.boardToFen()), this.replaceMove(o, n, !0, !0, !1, !1, !0)), n.beforeComment && this.insertCommentIntoMoveDisplay(n, n.beforeComment, !1), n.afterComment && this.insertCommentIntoMoveDisplay(n, n.afterComment, !0), clog && console.log("about to make move:" + n.output() + " with board pos:" + this.boardToFen()), this.makeMove(n, this.boardPieces[n.fromColumn][n.fromRow], !1, this.moveAnimationLength, !1, !1), clog && console.log("made move"), this.setCurrentMove(n, !0, !0), n.numVars > 0) {
                var h = n.index, c = n.prev, d = -1;
                c && (d = c.index);
                var u = n.numVars, v = n.vars;
                n.numVars = 0, n.vars = [];
                for (var m = 0; u > m; m++)this.gotoMoveIndex(d, !0, !0, !0, !0), clog && console.log("about to call insertMovesFromMoveList with head of variation"), this.insertMovesFromMoveList(v[m], !0, n, null, 0), clog && console.log("about to reset currentMoveIndex  after variation insert:" + h);
                this.gotoMoveIndex(h, !0, !0, !0, !0), this.backMove();
                var p = this.currentMove;
                this.makeMove(p, this.boardPieces[p.fromColumn][p.fromRow], !1, this.moveAnimationLength, !1, !1), clog && console.log(this.currentMove ? "popped up from variation, current set back to:" + this.currentMove.output() : "popped up from variation, current set to null")
            }
            if (n = l, a++, s > 0 && a >= s)break
        }
        if (r && this.gotoMoveIndex(-1, !1, !1, !1, !1), clog)for (var g = this.currentMove; g;)console.log("m:" + g.output()), g = g.next;
        ctime && r && console.timeEnd("insertMovesFromMoveList")
    }
},Board.prototype.setupFromLalgArrayIncremental = function (e, t, o, i) {
    if (this.outputFirstVar = !1,
        this.movesDisplay && this.lastCount) {
        this.movesDisplay.pendingLevelZeroCommentaryClose = !1;
        for (var s = 0; s < this.lastCount; s++) {
            var r = YAHOO.util.Dom.get(this.boardName + "-m" + s);
            r && YAHOO.util.Event.purgeElement(r)
        }
    }
    var a = 0, n = 2 * o - 1, l = "", h = !1, c = !1, d = ChessPiece.WHITE, u = !1, v = !0;
    this.currentMove = null;
    for (var s = 0; s < e.length; s++)if ("}" != e[s])if (u)l += e[s] + " "; else if ("{" != e[s])if ("(" != e[s])if (")" != e[s]) {
        if ("$" != e[s].charAt(0)) {
            var m = this.createMoveFromString(e[s]), p = !1;
            v && this.boardPieces[m.fromColumn][m.fromRow].colour == ChessPiece.BLACK && (n++, p = !0, d = ChessPiece.BLACK), this.startMoveNum = n, v = !1, m.index = a++;
            var g = m.moveString;
            g = Board.moveToLocale(g), d = d == ChessPiece.BLACK ? ChessPiece.WHITE : ChessPiece.BLACK, this.insertMoveAfter(this.currentMove, m), clog && m.prev && console.log(m.prev.next ? "move.prev.next:" + m.prev.next.output() : "move.prev:" + m.prev.output() + " next null"), this.makeMove(m, this.boardPieces[m.fromColumn][m.fromRow], !1, this.moveAnimationLength, !1, !1), this.setCurrentMove(m)
        }
    } else c = !0; else h = !0; else l = "", u = !0; else u = !1, this.movesDisplay && (l = l.replace(/\s+$/g, ""));
    this.gotoMoveIndex(-1, !1, !1, !1, !1)
},Board.prototype.displayPendingMoveList = function () {
    if (this.pendingMovesOutput && this.movesDisplay) {
        var e = this.movesDisplay.getMovesDisplay();
        if (e) {
            e.innerHTML = this.pendingMovesOutput;
            var t = new YAHOO.util.Scroll(e, {scroll: {to: [0, 0]}}, 0);
            t.animate()
        }
        if (this.movesDisplay)for (var o = 0; o < this.pendingMovesOutputCount; o++) {
            var i = YAHOO.util.Dom.get(this.boardName + "-m" + o);
            if (i && (YAHOO.util.Event.addListener(i, "click", this.movesDisplay.gotoMove, this.movesDisplay, !0), this.handleCommentClicks)) {
                var s = YAHOO.util.Dom.get(this.boardName + "-mcb" + o);
                s && YAHOO.util.Event.addListener(s, "click", this.movesDisplay.clickComment, this.movesDisplay, !0), s = YAHOO.util.Dom.get(this.boardName + "-mca" + o), s && YAHOO.util.Event.addListener(s, "click", this.movesDisplay.clickComment, this.movesDisplay, !0)
            }
        }
    }
},Board.prototype.setMoveSequence = function (e, t, o, i) {
    this.tacticMoveArray = new Array, this.moveArray = this.tacticMoveArray, this.setMoveSeqLalg(e, this.tacticMoveArray, o, i), this.tacticsmoveArrayLastMoveIndex = this.lastMoveIndex, this.fullmoveArray = null, this.lastMoveIndex = this.tacticsmoveArrayLastMoveIndex
},Board.prototype.resetVariationsPreviousNodes = function (e, t) {
    if (e.numVars > 0)for (var o = 0; o < e.numVars; o++)e.vars[o].prev = t, this.resetVariationsPreviousNodes(e.vars[o], t)
},Board.prototype.reconnectNextNodeVariations = function (e, t) {
    if (t && t.numVars > 0)for (var o = 0; o < t.numVars; o++)t.vars[o].prev = e, this.reconnectNextNodeVariations(e, t.vars[o])
},Board.prototype.findFirstMoveFromList = function (e) {
    for (var t = e; t && null != t.prev;)t = t.prev;
    return t
},Board.prototype.findVariationHeadFromMove = function (e) {
    for (var t = e; t && t.prev && t.prev.next == t;)t = t.prev;
    if (t && t.prev && t.prev.next != t)return t;
    if (t && !t.prev) {
        var o = this.moveArray[0];
        if (t != o)return t
    }
    return null
},Board.prototype.liftVariation = function (e) {
    if (e) {
        var t = null, o = null;
        e.prev ? t = e.prev.next : (t = this.moveArray[0], o = e);
        var i = null;
        if (this.currentMove && this.currentMove.prev && (i = this.currentMove.prev), t) {
            var s = t.numVars, r = t.vars;
            t.numVars = 0, t.vars = [], 0 == e.numVars && (e.vars = []);
            for (var a = 0; s > a; a++) {
                var n = r[a];
                clog && console.log("processing var:" + n.output()), n == e ? (clog && console.log("inserted parent var"), e.vars.push(t), e.numVars++) : (e.vars.push(n), e.numVars++)
            }
            e.prev && (e.prev.next = e), clog && console.log("finished moving variations"), o || (o = this.findFirstMoveFromList(e)), this.moveArray[0] = o, this.gotoMoveIndex(-1, !0, !0, !0, !0), clog && console.log("fm:" + o.output()), this.insertMovesFromMoveList(o)
        }
        i && this.gotoMoveIndex(i.index)
    }
},Board.prototype.deleteMoveAndLine = function (e) {
    var t = e, o = t, i = !1, s = null, r = this.moveArray[0], a = null;
    clog && console.log("delete line:" + e.output()), clog && console.log("delete line prev:" + e.prev), clog && e.prev && console.log("delete line prev.next:" + e.prev.next), e && e.prev && e.prev.next != e ? (clog && console.log("var is head and not front of move list"), i = !0, s = e.prev.next) : e && !e.prev && e != this.moveArray[0] && (clog && console.log("var is head and front of move list"), i = !0, s = this.moveArray[0]), clog && console.log("isVariationHead:" + i), clog && console.log("fm:" + r.output());
    var n = t.prev;
    if (i) {
        if (a = s, s) {
            clog && console.log("delete variation from parent:" + s.output());
            for (var l = [], h = 0; h < s.numVars; h++)s.vars[h] != o ? (clog && console.log("saving var:" + s.vars[h].output()), l.push(s.vars[h])) : clog && console.log("dropping var:" + s.vars[h].output());
            s.vars = l, s.numVars = l.length
        }
    } else {
        if (!n) {
            clog && console.log("deleting entire list"), this.movesDisplay && (this.movesDisplay.firstNonMove = !1, YAHOO.util.Event.purgeElement(this.movesDisplay.getMovesDisplay(), !0), this.movesDisplay.pendingLevelZeroCommentaryClose = !1);
            var c = this.movesDisplay.getMovesDisplay();
            return c && (c.innerHTML = ""), this.currentMove = null, this.startMoveNum = r.moveNum, clog && console.log("startFen:" + this.startFen), this.moveIndex = -1, this.moveArray = [], this.setupFromFen(this.startFen), this.lastFromSquare && YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), this.lastToSquare && YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), void this.setForwardBack()
        }
        n.next = null, a = n
    }
    this.moveArray[0] = r, this.gotoMoveIndex(-1, !0, !0, !0, !0), clog && console.log("fm:" + r.output()), this.insertMovesFromMoveList(r), a && this.gotoMoveIndex(a.index)
},Board.prototype.insertMoveAfter = function (e, t, o, i, s, r) {
    addToMovelist = !o, clog && console.log("addToMovelist:" + addToMovelist);
    var a = "null";
    if (e && (a = e.output()), clog && console.log("insert newMove:" + t.output() + " after:" + a), null == e)this.currentMove = t, t.atEnd = 0, t.prev = null, t.next = null, this.firstMove = t, this.currentMove.moveNum = this.startMoveNum > 0 ? this.startMoveNum : this.toMove == ChessPiece.WHITE ? 1 : 2, clog && console.log("startMoveNum:" + this.startMoveNum + " currMoveNum:" + this.currentMove.moveNum); else {
        if (t.atEnd = e.atEnd, t.prev = e, e.atEnd = 0, clog && e.next && console.log("prevMove.next:" + e.next.output()), t.equals(e.next) || t.equals(e)) {
            clog && console.log("inserting move that already exists in variation:" + e.next.output());
            var n = e.next;
            this.firstMove == n && (this.firstMove = t), t.equals(e) && (n = e), n.prev && n.prev.next == n && (n.prev.next = t), n.next && (n.next.prev = t), addToMovelist = !1, t.moveNum = n.moveNum, t.ravLevel = n.ravLevel, t.index = n.index, t.fen = n.fen, t.nextFen = n.nextFen, t.bestMoves = n.bestMoves, t.correctMove = n.correctMove, t.wrongMove = n.wrongMove, t.next = n.next, t.vars = n.vars, t.numVars = n.numVars, this.reconnectNextNodeVariations(t, n.next), this.moveArray[t.index] = t, this.currentMove == n && this.setCurrentMove(t)
        } else t.moveNum = e.moveNum + 1, t.ravLevel = e.ravLevel, t.next = e.next, t.next && (t.next.prev = t);
        e.next = t
    }
    if (addToMovelist && this.insertIntoMoveDisplay(e, t, i, s, r), null == t.next) {
        var l = this.createMoveFromString("i1i2");
        t.next = l, l.prev = t, l.moveNum = t.moveNum + 1, l.ravLevel = t.ravLevel, l.next = null, l.atEnd = 1, l.endNode = !0, clog && console.log("created endmove node in insertAfterMove:" + l.output())
    } else clog && console.log("allready had a node at end:" + t.next.output()), t.next.moveNum = t.moveNum + 1
},Board.prototype.replaceIntoMoveDisplay = function (e, t, o, i, s) {
    var r = "null";
    if (e && (r = e.output()), clog && console.log("replace display newMove:" + t.output() + " after:" + r + " hideScore:" + i), e) {
        clog && console.log("about to get movesdsiplay in replace into move display:" + this.movesDisplay);
        var a = this.movesDisplay.getMovesDisplay();
        if (clog && console.log("got moves display"), !a)return void(clog && console.log("no movesd disiplay in replace into move display"));
        var n = t.SAN;
        n || (clog && console.log("about to make san"), n = this.makeShortAlgabraic(t.fromColumn, t.fromRow, t.toColumn, t.toRow, t), clog && console.log("about to made san:" + n), t.SAN = n), clog && console.log("oldMove.index:" + e.index);
        var l = this.boardName + "-ms" + e.index, h = -1;
        e.next && (h = this.boardName + "-m" + e.next.index), clog && console.log("oldMoveId:" + l);
        var c = YAHOO.util.Dom.get(l), d = YAHOO.util.Dom.get(h);
        if (o) {
            this.moveIndex++, t.index = this.moveIndex, this.moveArray[this.moveIndex] = t, clog && console.log("replace as variation old:" + e.output() + " new:" + t.output());
            var u = document.createElement("span");
            ("undefined" == typeof e.ravlevel || 0 == e.ravlevel) && YAHOO.util.Dom.addClass(u, "ct-top-var-start");
            var v = this.movesDisplay.outputVariationStart(0, 0, t.moveNum, 0);
            t.ravLevel = e.ravlevel + 1;
            var r = Board.moveToLocale(n);
            null == t.prev && (this.movesDisplay.firstNonMove = !1);
            var m = this.movesDisplay.outputMove(this.moveIndex, t.ravLevel, t.moveNum, r, o, 0, t.moveNum, t, i, s), p = document.createElement("span");
            p.id = this.boardName + "-ms" + t.index, p.innerHTML = m + "&nbsp;";
            var g = this.movesDisplay.outputVariationEnd(0, 0, t.moveNum, 0);
            this.movesDisplay.firstNonMove = !0;
            var f = document.createElement("span");
            f.innerHTML = v;
            var b = document.createElement("span");
            b.innerHTML = g, u.appendChild(f);
            var C = YAHOO.util.Dom.getElementsByClassName("ct-mainline-commentary", "div", u), y = u;
            if (C.length > 0 && (y = C[0]), y.appendChild(p), y.appendChild(b), c.appendChild(u), d) {
                var C = YAHOO.util.Dom.getElementsByClassName("ct-board-move-movenum", "span", d);
                if (0 == C.length) {
                    var M = e.next.moveNum, O = "" + Math.round(M / 2) + ". ", P = !1;
                    M % 2 != 1 && (clog && console.log("firstRav:" + firstRav + " firstNonMove:" + this.firstNonMove), O = Math.round(M / 2) + "... ", P = !0);
                    var p = document.createElement("span");
                    p.className = "ct-board-move-movenum", p.innerHTML = O, insertBefore(p, d.firstChild), p = document.createElement("span"), P && (p.className = "ct-board-move-dottedempty", p.innerHTML = "&nbsp;", insertAfter(p, d.firstChild))
                }
            }
        } else {
            t.index = e.index, this.moveArray[t.index] = t;
            var r = Board.moveToLocale(n);
            null == t.prev && (this.movesDisplay.firstNonMove = !1);
            var m = this.movesDisplay.outputMove(t.index, t.ravLevel, t.moveNum, r, o, 0, t.moveNum, t, i, s), p = document.createElement("span");
            p.innerHTML = m + "&nbsp;", p.id = this.boardName + "-ms" + t.index;
            var A = [];
            if (c && c.childNodes)for (var S = 1; S < c.childNodes.length; S++)A[S - 1] = c.childNodes[S];
            if (clog && console.log("replace as main line not variation old:" + e.output() + " new:" + t.output()), c.parentNode.replaceChild(p, c), A)for (var S = 0; S < A.length; S++)p.appendChild(A[S])
        }
        YAHOO.util.Event.removeListener(this.boardName + "-m" + t.index), YAHOO.util.Event.addListener(this.boardName + "-m" + t.index, "click", this.movesDisplay.gotoMove, this.movesDisplay, !0)
    } else clog && console.log("null oldMove"), this.insertIntoMoveDisplay(null, t, !1, i)
},Board.prototype.insertCommentIntoMoveDisplay = function (e, t, o) {
    var i = this.movesDisplay.getMovesDisplay();
    if (i) {
        var s = "b";
        if (o && (s = "a"), e) {
            var r = this.boardName + "-mc" + s + e.index, a = YAHOO.util.Dom.get(r), n = !1;
            a || (a = document.createElement("span"), a.id = r, n = !0);
            var l = e.moveNum % 2 != 1, h = !l && !o;
            clog && console.log("dontResetFirstNoneMove:" + h + " isBlackMoveNum:" + l + " insertCommentAfter:" + o + " move.moveNum:" + e.moveNum + " comment:" + t), a.innerHTML = this.movesDisplay.outputComment(t, 0, !1, h);
            var c = YAHOO.util.Dom.get(this.boardName + "-m" + e.index);
            c && (o ? (e.afterComment = t, n && insertAfter(a, c)) : (e.beforeComment = t, n && insertBefore(a, c))), a && n && this.handleCommentClicks && YAHOO.util.Event.addListener(a, "click", this.movesDisplay.clickComment, this.movesDisplay, !0)
        }
    }
},Board.prototype.insertIntoMoveDisplay = function (e, t, o, i, s) {
    var r = this.movesDisplay.getMovesDisplay();
    if (r) {
        if (clog) {
            var a = "null";
            e && (a = e.output()), console.log("insert display newMove:" + t.output() + " after:" + a)
        }
        var n = t.SAN;
        n || (n = this.makeShortAlgabraic(t.fromColumn, t.fromRow, t.toColumn, t.toRow, t), t.SAN = n), this.moveIndex++, t.index = this.moveIndex, this.moveArray[this.moveIndex] = t;
        var a = Board.moveToLocale(n), l = !1, h = null;
        if (e && (h = YAHOO.util.Dom.get(this.boardName + "-ms" + e.index)), h) {
            var c = YAHOO.util.Dom.getElementsByClassName("ct-mainline-commentary", "div", h);
            c.length > 0 && (l = !0)
        }
        var d = this.movesDisplay.outputMove(this.moveIndex, t.ravLevel, t.moveNum, a, l, 0, t.moveNum, t, i, s), u = document.createElement("span");
        if (u.innerHTML = d + "&nbsp;", u.id = this.boardName + "-ms" + this.moveIndex, o && YAHOO.util.Dom.setStyle(u, "visibility", "hidden"), e)clog && console.log("prevMove.index:" + e.index + "prevMove:" + e.output()), h ? insertAfter(u, h) : r.appendChild(u); else if (t.next) {
            var v = YAHOO.util.Dom.get(this.boardName + "-ms" + t.next.index);
            insertBefore(u, v)
        } else r.appendChild(u);
        YAHOO.util.Event.removeListener(this.boardName + "-m" + this.moveIndex), YAHOO.util.Event.addListener(this.boardName + "-m" + this.moveIndex, "click", this.movesDisplay.gotoMove, this.movesDisplay, !0)
    }
},Board.prototype.replaceMove = function (e, t, o, i, s, r, a) {
    var n = "null";
    e && (n = e.output()), clog && (console.log("replace newMove:" + t.output() + " after:" + n + " replace as var" + o + " rep move display:" + i + " hideScore:" + s + " replaceAsVariationEvenIfSame:" + a), e && e.prev && console.log("replace oldMove.prev:" + e.prev.output()), e && e.next && console.log("replace oldMove.next:" + e.next.output()));
    var l = !1, h = null, c = 0;
    if (e.endNode)return clog && console.log("asked to replace endNode,inserting before instead"), this.insertMoveAfter(e.prev, t, !1, !1, s, r), t.fen = e.fen, void(t.nextFen = e.nextFen);
    if (!a && t.equals(e))clog && console.log("new move is same as old move so not replacing as variation"), o = !1; else if (!a && e && e.numVars > 0)for (var d = 0; d < e.numVars; d++) {
        var u = e.vars[d];
        if (t.equals(u)) {
            clog && (console.log("new move is same as an existing variation varNum:" + d), console.log("variation:" + u.output()), u.next && console.log("variation next:" + u.next.output())), l = !0, h = e, e = u, c = d;
            break
        }
    }
    if (null == e)clog && console.log("replaced new move with null oldmove"), this.currentMove = t, t.atEnd = 1, t.next = null, t.prev = null, this.startPositionAfterOpponentMove && (t.fen = this.startPositionAfterOpponentMove, t.nextFen = null), this.currentMove.moveNum = this.toMove == ChessPiece.WHITE ? 1 : 2, this.firstMove = t; else {
        var v = !1;
        if (e && e.prev && e.prev.next != e && (v = !0), this.currentMove != e || o ? clog && console.log("not setting current move in replacemove") : this.currentMove = t, t.atEnd = e.atEnd, t.prev = e.prev, t.next = e.next, t.fen = e.fen, t.nextFen = e.nextFen, t.bestMoves = e.bestMoves, t.correctMove = e.correctMove, t.wrongMove = e.wrongMove, t.moveNum = e.moveNum, t.ravLevel = e.ravLevel, t.index = e.index, clog && console.log("replacingVariation with var not null:" + l), l)return h.vars[c] = t, t.vars = e.vars, t.numVars = e.numVars, this.reconnectNextNodeVariations(t, e.next), e.next && (e.next.prev = t), this.moveArray[t.index] = t, void(clog && (console.log("replacing existing sub variation of main line"), t.next && console.log("next of replacement variation:" + t.next.output())));
        if (o) {
            clog && console.log("replacing as variation"), 0 == e.numVars && (e.vars = new Array), e.vars[e.numVars++] = t, e.atEnd = 0, t.next = null;
            var m = this.createMoveFromString("i1i2");
            t.next = m, m.prev = t, m.next = null, m.atEnd = 1, m.moveNum = t.moveNum + 1, m.ravLevel = t.ravLevel, m.endNode = !0
        } else clog && console.log("not replacing as variation"), !v && e.prev && (e.prev.next = t), e.next && (e.next.prev = t), t.vars = e.vars, t.numVars = e.numVars, this.reconnectNextNodeVariations(t, e.next), this.firstMove == e && (this.firstMove = t), this.moveArray[t.index] = t
    }
    i && this.replaceIntoMoveDisplay(e, t, o, s, r)
},Board.prototype.setCurrentMove = function (e, t, o) {
    if (this.cloned || null == this.currentMove || null != this.currentMove.prev && YAHOO.util.Dom.removeClass(this.boardName + "-m" + this.currentMove.prev.index, "ct-board-move-current"), this.currentMove = e, this.cloned || null == this.currentMove || null == this.currentMove.prev)null == e && clog && console.log("attempted to set current move on null node"); else {
        var i = this.boardName + "-m" + this.currentMove.prev.index;
        clog && console.log("setCurrentMove attempted highlight of id:" + i + " for move:" + e.output());
        var s = YAHOO.util.Dom.get(i);
        if (s) {
            var r = s.className;
            if (YAHOO.util.Dom.addClass(s, "ct-board-move-current"), this.autoScrollMoves && !o && (this.scrollVariations || -1 == r.indexOf("ct-board-move-variation"))) {
                var a = this.movesDisplay.getMovesDisplay();
                if (a) {
                    var n = 0;
                    a && a.offsetHeight && (n = a.offsetHeight / 2);
                    var l = YAHOO.util.Dom.getY(s) - (YAHOO.util.Dom.getY(a) + n), h = new YAHOO.util.Scroll(a, {scroll: {by: [0, l - this.scrollOffsetCorrection]}}, this.moveAnimationLength, YAHOO.util.Easing.easeOut);
                    h.animate()
                }
            }
        }
    }
    t || this.setForwardBack()
},Board.prototype.distanceFromInitial = function () {
    var e = this.cloneBoard();
    e.setupFromFen(Board.INITIAL_FEN, !1, !1, !0, !1, !1);
    for (var t = 0, o = 0; 8 > o; o++)for (var i = 0; 8 > i; i++) {
        var s = this.boardPieces[o][i], r = e.boardPieces[o][i];
        s != r && r && (s ? (s.piece != r.piece || s.colour != r.colour) && t++ : t++)
    }
    return t
},Board.INITIAL_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",Board.isFenLegal = function (e) {
    function t(e) {
        if (!e)return !1;
        e = e.toLowerCase();
        for (var t = 0; t < e.length; t++)if ("q" != e.charAt(t) && "k" != e.charAt(t) && "-" != e.charAt(t))return !1;
        return !0
    }

    function o(e) {
        if (!e)return !1;
        if ("-" == e)return !0;
        if (2 != e.length)return !1;
        if (e.charAt(0) < "a" || e.charAt(0) > "h")return !1;
        var t = parseInt(e.charAt(1));
        return isNaN(t) || 1 > t || t > 8 ? !1 : !0
    }

    if (!e)return !1;
    var i = e.split(" ");
    if (6 != i.length)return !1;
    var s = i[0].split("/");
    return 8 != s.length ? !1 : "w" != i[1] && "b" != i[1] ? !1 : isNaN(parseInt(i[4])) ? !1 : isNaN(parseInt(i[5])) ? !1 : t(i[2]) && o(i[3]) ? !0 : !1
},Board.prototype.boardToUniqueFen = function (e) {
    var t = this.boardToFen(), o = t.split(" "), i = "w";
    e == ChessPiece.BLACK && (i = "b");
    var s = o[0] + " " + i + " " + o[2] + " " + o[3];
    return s
},Board.prototype.boardToFen = function (e) {
    for (var t = "", o = 7; o >= 0; o--) {
        var i = 0, s = "";
        7 > o && (s = "/");
        for (var r = 0; 8 > r; r++) {
            var a = this.boardPieces[r][o];
            if (a) {
                var n = "";
                i > 0 && (n = i + ""), s += n + a.getFenLetter(), i = 0
            } else i++
        }
        i > 0 && (s += i + ""), t += s
    }
    var l = t, h = " w ";
    e ? this.toMove == ChessPiece.WHITE && (h = " b ") : this.toMove == ChessPiece.BLACK && (h = " b "), l += h;
    var c = "";
    c += Board.getFenCastleChar(this.canCastleKingSide, "K", ChessPiece.WHITE), c += Board.getFenCastleChar(this.canCastleQueenSide, "Q", ChessPiece.WHITE), c += Board.getFenCastleChar(this.canCastleKingSide, "K", ChessPiece.BLACK), c += Board.getFenCastleChar(this.canCastleQueenSide, "Q", ChessPiece.BLACK), l += "" == c ? "- " : c + " ";
    var d = null;
    d = this.currentMove && this.currentMove.prev ? this.currentMove.prev : this.prev_move;
    var u = "- ";
    if (d) {
        var v = this.boardPieces[d.toColumn][d.toRow];
        v && v.piece == ChessPiece.PAWN && (v.colour == ChessPiece.WHITE ? 1 == d.fromRow && 3 == d.toRow && (u = Move.columnToChar(d.fromColumn) + "3 ") : 6 == d.fromRow && 4 == d.toRow && (u = Move.columnToChar(d.fromColumn) + "6 "))
    }
    return l += u, l += this.halfMoveNumber + " " + parseInt((this.moveNumber + 1) / 2), clog && console.log("moveNumber:" + this.moveNumber + " fen:" + l), l
},Board.getFenCastleChar = function (e, t, o) {
    return e[o] ? o == ChessPiece.WHITE ? t.toUpperCase() : t.toLowerCase() : ""
},Board.prototype.getCastlingString = function (e) {
    var t = _js("None");
    return this.canCastleKingSide[e] && (t = "O-O"), this.canCastleQueenSide[e] && (t == _js("None") ? t = "O-O-O" : t += ",O-O-O"), t
},Board.prototype.updateToPlay = function () {
    if (!this.disableUpdateToPlay) {
        this.showToMoveIndicators && (this.isFlipped ? (YAHOO.util.Dom.setStyle(this.boardName + "-top-to-move-inner", "background-color", "white"), YAHOO.util.Dom.setStyle(this.boardName + "-top-to-move-inner", "border", "1px solid black"), YAHOO.util.Dom.setStyle(this.boardName + "-bottom-to-move-inner", "background-color", "black"), YAHOO.util.Dom.setStyle(this.boardName + "-bottom-to-move-inner", "border", "1px solid white")) : (YAHOO.util.Dom.setStyle(this.boardName + "-bottom-to-move-inner", "background-color", "white"), YAHOO.util.Dom.setStyle(this.boardName + "-bottom-to-move-inner", "border", "1px solid black"), YAHOO.util.Dom.setStyle(this.boardName + "-top-to-move-inner", "background-color", "black"), YAHOO.util.Dom.setStyle(this.boardName + "-top-to-move-inner", "border", "1px solid white")), this.toMove == ChessPiece.WHITE ? this.isFlipped ? (YAHOO.util.Dom.addClass(this.boardName + "-top-to-move-outer", "ct-to-move-active"), YAHOO.util.Dom.removeClass(this.boardName + "-bottom-to-move-outer", "ct-to-move-active")) : (YAHOO.util.Dom.addClass(this.boardName + "-bottom-to-move-outer", "ct-to-move-active"), YAHOO.util.Dom.removeClass(this.boardName + "-top-to-move-outer", "ct-to-move-active")) : this.isFlipped ? (YAHOO.util.Dom.addClass(this.boardName + "-bottom-to-move-outer", "ct-to-move-active"), YAHOO.util.Dom.removeClass(this.boardName + "-top-to-move-outer", "ct-to-move-active")) : (YAHOO.util.Dom.addClass(this.boardName + "-top-to-move-outer", "ct-to-move-active"), YAHOO.util.Dom.removeClass(this.boardName + "-bottom-to-move-outer", "ct-to-move-active")));
        var e = YAHOO.util.Dom.get("toPlay");
        if (null != e) {
            this.toMove == ChessPiece.WHITE ? (e.src = "/images/whiteknight" + this.getVersString() + ".gif", e.alt = _js("White to play")) : (e.src = "/images/blackknight" + this.getVersString() + ".gif", e.alt = _js("Black to play"));
            var t = YAHOO.util.Dom.get("fenStatus");
            if (t) {
                var o = this.getCastlingString(ChessPiece.BLACK), i = this.getCastlingString(ChessPiece.WHITE), s = "<div><span>" + _js("White Castling: ") + "</span><span>" + i + "</span></div><div><span>" + _js("Black Castling: ") + "</span><span>" + o + "</span></div>";
                t.innerHTML = s
            }
        }
    }
},Board.prototype.getBoardDivFromId = function (e) {
    return this[e] || (this[e] = YAHOO.util.Dom.get(e)), this[e]
},Board.prototype.getBoardDiv = function () {
    return this.boardDiv || (this.boardDiv = YAHOO.util.Dom.get("ctb-" + this.boardName)), this.boardDiv
},Board.prototype.getDocBody = function () {
    if (!this.docBody) {
        var e = document.getElementsByTagName("body");
        null == e || 0 == e.length ? alert("Could not find body tag") : this.docBody = e[0]
    }
    return this.docBody
},Board.prototype.getPieceDragDiv = function () {
    return this.pieceDragDiv || (this.pieceDragDiv = YAHOO.util.Dom.get("pieceDragDiv")), this.pieceDragDiv
},Board.prototype.createBoardCoords = function () {
    this.coordinatesShown = !1;
    var e = YAHOO.util.Dom.get(this.boardName + "-fileLabels"), t = YAHOO.util.Dom.get(this.boardName + "-rankLabels");
    if (e && t) {
        YAHOO.util.Event.purgeElement(e, !0), t.innerHTML = "", e.innerHTML = "";
        var o = YAHOO.util.Dom.get(this.boardName + "-boardBorder");
        if (!this.showCoordinates) {
            YAHOO.util.Dom.setStyle(e, "display", "none"), YAHOO.util.Dom.setStyle(t, "display", "none");
            var i = 0;
            return YAHOO.util.Dom.setStyle(o, "width", 8 * this.pieceSize + i + "px"), void YAHOO.util.Dom.setStyle(o, "height", 8 * this.pieceSize + i + "px")
        }
        YAHOO.util.Dom.setStyle(e, "display", "block"), YAHOO.util.Dom.setStyle(t, "display", "block");
        var i = 15, s = 0;
        check_bad_msie() && (s = this.ie6FixCoordsOffsetSize), YAHOO.util.Event.isIE && (s += this.allIeFixCoordsOffsetSize, "CSS1Compat" != document.compatMode && (s = 8)), YAHOO.util.Dom.setStyle(o, "width", 8 * this.pieceSize + i + s + "px"), YAHOO.util.Dom.setStyle(o, "height", 8 * this.pieceSize + i + "px"), this.coordinatesShown = !0;
        for (var r = 0; 8 > r; r++) {
            var a = document.createElement("div");
            YAHOO.util.Dom.setStyle(a, "height", this.pieceSize + "px"), YAHOO.util.Dom.setStyle(a, "width", "15px"), YAHOO.util.Dom.setStyle(a, "text-align", "center"), YAHOO.util.Dom.setStyle(a, "line-height", this.pieceSize + "px"), a.innerHTML = this.isFlipped ? "" + (r + 1) : "9" - (r + 1), t.appendChild(a)
        }
        for (var r = 0; 9 > r; r++) {
            var n = document.createElement("span");
            if (YAHOO.util.Dom.setStyle(n, "float", "left"), YAHOO.util.Dom.setStyle(n, "height", "15px"), 0 == r) {
                YAHOO.util.Dom.setStyle(n, "width", "15px"), YAHOO.util.Dom.setStyle(n, "clear", "both"), YAHOO.util.Dom.setStyle(n, "margin-top", "-5px"), s ? YAHOO.util.Dom.setStyle(n, "margin-left", "-3px") : YAHOO.util.Dom.setStyle(n, "margin-left", "-2px");
                var l = "";
                l = this.isFlipped ? "whiteblack-flipper" + this.getVersString() + ".png" : "blackwhite-flipper" + this.getVersString() + ".png", n.innerHTML = '<span><img id="' + this.boardName + '-flipper" title="' + _js("Flip Board") + '" src="' + this.boardImagePath + "/images/" + l + '"/></span>', this.disableFlipper || YAHOO.util.Event.addListener(this.boardName + "-flipper", "click", this.flipBoard, this, !0)
            } else YAHOO.util.Dom.setStyle(n, "width", this.pieceSize + "px"), YAHOO.util.Dom.setStyle(n, "text-align", "center"), n.innerHTML = _js(this.isFlipped ? Move.columnToChar(8 - r) : Move.columnToChar(r - 1));
            e.appendChild(n)
        }
        var h = YAHOO.util.Dom.get(this.boardName + "-flipper");
        h && fix_ie_png(h)
    }
},Board.prototype.showNavigation = function () {
    this.disableNavigation = !1, YAHOO.util.Dom.setStyle(this.boardName + "-ct-nav-container", "display", "block")
},Board.prototype.hideNavigation = function () {
    this.disableNavigation = !0, YAHOO.util.Dom.setStyle(this.boardName + "-ct-nav-container", "display", "none")
},Board.prototype.createBoardUI = function () {
    var e = this.boardName + "-container", t = YAHOO.util.Dom.get(e);
    if (null == t)return void alert("Could not find board container:" + e);
    YAHOO.util.Dom.addClass(t, "ct-board-container"), this.boardDiv = null;
    var o = document.createElement("div");
    o.id = this.boardName + "-boardBorder", YAHOO.util.Dom.addClass(o, "ct-board-border" + this.squareColorClass);
    var i = 0;
    this.showCoordinates && (i = 15), YAHOO.util.Dom.setStyle(o, "width", 8 * this.pieceSize + i + "px"), YAHOO.util.Dom.setStyle(o, "height", 8 * this.pieceSize + i + "px");
    var s = document.createElement("div");
    YAHOO.util.Dom.setStyle(s, "float", "left"), s.id = this.boardName + "-rankLabels", o.appendChild(s);
    var r = document.createElement("div");
    YAHOO.util.Dom.addClass(r, "ct-board"), YAHOO.util.Dom.setStyle(r, "width", 8 * this.pieceSize + "px"), YAHOO.util.Dom.setStyle(r, "height", 8 * this.pieceSize + "px"), r.id = "ctb-" + this.boardName;
    for (var a = "ct-white-square" + this.squareColorClass, n = "", l = [], h = 7; h >= 0; h--) {
        for (var c = "<div>", d = 0; 8 > d; d++) {
            var u = (document.createElement("div"), this.boardName + "-s" + d + h), v = (d + 1) * (h + 1) % 19 / 19 * 100, m = (65 - (d + 1) * (h + 1)) % 19 / 19 * 100;
            c += '<div id="' + u + '" class="' + a + '" style="width:' + this.pieceSize + "px;height:" + this.pieceSize + "px;background-position:" + v + "% " + m + '%"></div>', l.push(u), a = a == "ct-black-square" + this.squareColorClass ? "ct-white-square" + this.squareColorClass : "ct-black-square" + this.squareColorClass
        }
        a = a == "ct-black-square" + this.squareColorClass ? "ct-white-square" + this.squareColorClass : "ct-black-square" + this.squareColorClass, c += "</div>", n += c
    }
    r.innerHTML = n;
    var p = document.createElement("div");
    if (p.id = this.boardName + "-fileLabels", o.appendChild(r), o.appendChild(p), t.appendChild(o), this.showToMoveIndicators) {
        var g = document.createElement("div");
        g.id = this.boardName + "-moveIndicators", YAHOO.util.Dom.addClass(g, "ct-move-indicators"), g.innerHTML = '<div class="ct-top-to-move-outer" id="' + this.boardName + '-top-to-move-outer"><div  class="ct-top-to-move-inner" id="' + this.boardName + '-top-to-move-inner"></div></div><div class="ct-bottom-to-move-outer"  id="' + this.boardName + '-bottom-to-move-outer"><div class="ct-bottom-to-move-inner" id="' + this.boardName + '-bottom-to-move-inner" ></div>', t.appendChild(g), YAHOO.util.Dom.setStyle(o, "float", "left"), YAHOO.util.Dom.setStyle(g, "float", "left"), YAHOO.util.Dom.setStyle(g, "margin-left", "2px"), YAHOO.util.Dom.setStyle(g, "height", 8 * this.pieceSize + 2 + "px"), YAHOO.util.Dom.setStyle(g, "position", "relative");
        var f = document.createElement("div");
        YAHOO.util.Dom.setStyle(f, "clear", "both"), t.appendChild(f)
    }
    this.createBoardCoords();
    var b = !1, C = YAHOO.util.Dom.get(this.boardName + "-ct-nav-container");
    if (C ? (b = !0, C.innerHTML = "") : C = document.createElement("div"), C.id = this.boardName + "-ct-nav-container", !this.dontOutputNavButtons || this.r) {
        var y = "";
        this.dontOutputNavButtons || this.problem && this.problem.isEndgame || (y = '<span id="playStopSpan"><img class="ct-end" id="' + this.boardName + '-end" src="' + this.boardImagePath + "/images/resultset_last" + this.getVersString() + '.gif" alt="' + _js("End position") + '" title="' + _js("Go to final position") + '"/><img class="ct-play" id="' + this.boardName + '-play" src="' + this.boardImagePath + "/images/control_play_blue" + this.getVersString() + '.gif" alt="' + _js("Play moves") + '" title="' + _js("Play sequence of moves") + '"/><img class="ct-stop" id="' + this.boardName + '-stop" src="' + this.boardImagePath + "/images/control_stop_blue" + this.getVersString() + '.gif" alt="' + _js("Stop playing") + '" title="' + _js("Stop playing move sequence") + '"/></span>');
        var M = '<div class="ct-nav-buttons" id="' + this.boardName + '-navButtons"><span id="' + this.boardName + '-nav-buttons-only">';
        if (!this.dontOutputNavButtons) {
            var O = "";
            (isIphone || isIpad) && (O = ' width="50px" height="34px" ', y = ""), isIphone || isIpad || (M += '<img class="ct-start" id="' + this.boardName + '-start" src="' + this.boardImagePath + "/images/resultset_first" + this.getVersString() + '.gif" alt="' + _js("Start position") + '" title="' + _js("Go to starting position") + '"/>'), M += '<img class="ct-back" id="' + this.boardName + '-back" ' + O + ' src="' + this.boardImagePath + "/images/resultset_previous" + this.getVersString() + '.gif" alt="' + _js("Previous Move") + '" title="' + _js("Go back a move") + '"/><img class="ct-forward" id="' + this.boardName + '-forward" ' + O + ' src="' + this.boardImagePath + "/images/resultset_next" + this.getVersString() + '.gif" alt="' + _js("Next Move") + '" title="' + _js("Go forward a move") + '"/>' + y
        }
        if (this.r && (M += '<img class="ct-forward" id="' + this.boardName + '-analyse" src="' + this.boardImagePath + "/images/anboard" + this.getVersString() + '.gif" alt="' + _js("Analyse") + '" title="' + _js("Launch analysis board to explore different lines in this position") + '"/>', this.g || (M += '<img class="ct-forward" id="' + this.boardName + '-showfen" src="' + this.boardImagePath + "/images/copy_fen" + this.getVersString() + '.gif" alt="' + _js("Copy FEN") + '" title="' + _js("Show FEN for current position") + '"/>')), this.canPasteFen && (M += '<img class="ct-forward" id="' + this.boardName + '-pastefen" src="' + this.boardImagePath + "/images/paste_fen" + this.getVersString() + '.gif" alt="' + _js("Input FEN") + '" title="' + _js("Setup position from user supplied FEN or move list") + '"/>'), this.g2 && (M += '<img class="ct-forward" id="' + this.boardName + '-playcomp" src="' + this.boardImagePath + "/images/computer" + this.getVersString() + '.gif" alt="' + _js("Play Current Position vs Computer") + '" title="' + _js("Play current position against computer") + '"/>'), M += "</span>", M += "</div>", this.puzzle) {
            var P = "", A = "", S = "", w = "";
            this.pieceSize >= 29 ? (P = _js("Easy"), A = _js("Medium"), S = _js("Hard"), w = _js("Help")) : (P = _js("D1"), A = _js("D2"), S = _js("D3"), w = _js("?")), M += '<div><form action=""><button type="button" id="' + this.boardName + '-puzzleSolution" class="asolution-button">' + _js("Show") + '</button><button id="' + this.boardName + '-easyPuzzle" type="button" class="puzzle-difficulty">' + P + '</button><button id="' + this.boardName + '-mediumPuzzle" type="button" class="puzzle-difficulty">' + A + '</button><button id="' + this.boardName + '-hardPuzzle" type="button" class="puzzle-difficulty">' + S + '</button><button id="' + this.boardName + '-puzzleHelp" type="button" class="puzzle-difficulty">' + w + '</button><img alt="" class="ct-forward" id="' + this.boardName + '-problemState"></img><span id="' + this.boardName + '-puzzleResult"></span></form></div>', M += '<div class="initially_hidden initially_invisible" id="' + this.boardName + '-moves"></div>', M += '<div class="initially_hidden initially_invisible" id="' + this.boardName + '-moves"></div>'
        }
        C.innerHTML = M
    }
    if (b || t.appendChild(C), this.problem) {
        var N = YAHOO.util.Dom.get("body");
        N && YAHOO.util.Dom.setStyle(N, "min-width", 8 * this.pieceSize + i + 300 + 200 + 120 + "px")
    }
},Board.prototype.getPieceDiv = function () {
    var e = this.getBoardDiv(), t = document.createElement("div");
    return this.availPieceDivs[this.uptoId] = t, this.availIds[this.uptoId] = YAHOO.util.Dom.generateId(t), YAHOO.util.Dom.setStyle(t, "visibility", "hidden"), YAHOO.util.Dom.addClass(t, "board-piece-start-style"), e.appendChild(t), this.uptoId++, t
},Board.prototype.flipToMove = function (e) {
    return "w" == e ? "b" : "w"
},Board.prototype.pieceCharToPieceNum = function (e) {
    var t;
    switch (e) {
        case"K":
            t = ChessPiece.KING;
            break;
        case"Q":
            t = ChessPiece.QUEEN;
            break;
        case"R":
            t = ChessPiece.ROOK;
            break;
        case"B":
            t = ChessPiece.BISHOP;
            break;
        case"N":
            t = ChessPiece.KNIGHT;
            break;
        case"P":
            t = ChessPiece.PAWN
    }
    return t
},Board.prototype.pieceTypeToChar = function (e) {
    switch (e) {
        case ChessPiece.KING:
            return "K";
        case ChessPiece.QUEEN:
            return "Q";
        case ChessPiece.ROOK:
            return "R";
        case ChessPiece.BISHOP:
            return "B";
        case ChessPiece.KNIGHT:
            return "N";
        case ChessPiece.PAWN:
            return "P"
    }
    return "?"
},Board.prototype.canMoveKnight = function (e, t, o, i) {
    return e + 2 == o && t + 1 == i ? !0 : e + 2 == o && t - 1 == i ? !0 : e - 2 == o && t + 1 == i ? !0 : e - 2 == o && t - 1 == i ? !0 : e + 1 == o && t + 2 == i ? !0 : e - 1 == o && t + 2 == i ? !0 : e + 1 == o && t - 2 == i ? !0 : e - 1 == o && t - 2 == i ? !0 : !1
},Board.prototype.canMovePawn = function (e, t, o, i, s) {
    var r = this.boardPieces[o][i], a = this.boardPieces[e][t];
    if (s) {
        var n = this.boardPieces[s.toColumn][s.toRow];
        if (n && n.piece == ChessPiece.PAWN)if (n.colour == ChessPiece.WHITE) {
            if (1 == s.fromRow && 3 == s.toRow && o == s.fromColumn && 3 == t && 2 == i && (e == o + 1 || e == o - 1))return !0
        } else if (6 == s.fromRow && 4 == s.toRow && o == s.fromColumn && 4 == t && 5 == i && (e == o + 1 || e == o - 1))return !0
    }
    if (r) {
        if (a.colour == ChessPiece.WHITE) {
            if ((e == o + 1 || e == o - 1) && t == i - 1)return !0
        } else if ((e == o + 1 || e == o - 1) && t == i + 1)return !0
    } else if (e == o)if (a.colour == ChessPiece.WHITE) {
        if (1 == t) {
            if (2 == i)return !0;
            if (3 == i && null == this.boardPieces[o][2])return !0
        } else if (t + 1 == i)return !0
    } else if (6 == t) {
        if (5 == i)return !0;
        if (4 == i && null == this.boardPieces[o][5])return !0
    } else if (t - 1 == i)return !0;
    return !1
},Board.prototype.canMoveStraight = function (e, t, o, i, s, r) {
    var a = e, n = t, l = 0, h = 0;
    if (o > e ? l = 1 : e > o && (l = -1), i > t ? h = 1 : t > i && (h = -1), clog && console.log("deltaRow:" + h + " deltaCol:" + l + " fromCol:" + e + " fromRow:" + t + " toCol:" + o + " toRow:" + i), s == ChessPiece.ROOK && 0 != l && 0 != h)return !1;
    if (s == ChessPiece.BISHOP && (0 == l || 0 == h))return !1;

    for (var c = 0; ;) {
        if (c++, e += l, t += h, s == ChessPiece.KING && c > 1) {
            if (clog && console.log("king count:" + c + " toCol:" + o + " toRow:" + i), 2 != c)return !1;
            if (0 != h)return !1;
            if (6 != o && 2 != o)return !1;
            if (2 == o) {
                if (this.boardPieces[1][t] || this.boardPieces[2][t] || this.boardPieces[3][t])return !1;
                if (!this.canCastleQueenSide[r.colour])return !1
            } else {
                if (6 != o)return clog && console.log("king not in col 2 or 6"), !1;
                if (this.boardPieces[5][t] || this.boardPieces[6][t])return clog && console.log("king can't castle intervening piece"), !1;
                if (!this.canCastleKingSide[r.colour])return clog && console.log("king can't castle king side (made previously invalid) colour:" + r.colour), !1
            }
            var d = "";
            d += Move.columnToChar(a), d += String.fromCharCode("1".charCodeAt(0) + n), d += Move.columnToChar(a + l), d += String.fromCharCode("1".charCodeAt(0) + (n + h));
            var u = this.createMoveFromString(d), v = this.cloneBoard();
            if (v.makeMove(u, v.boardPieces[a][n], !1, this.moveAnimationLength, !1, !1), kingSafe = v.isKingSafe(r.colour, u), clog && console.log("kingSafe1:" + kingSafe), !kingSafe)return !1;
            var d = "";
            d += Move.columnToChar(a), d += String.fromCharCode("1".charCodeAt(0) + n), d += Move.columnToChar(a), d += String.fromCharCode("1".charCodeAt(0) + n);
            var u = this.createMoveFromString(d), v = this.cloneBoard();
            v.makeMove(u, v.boardPieces[a][n], !1, this.moveAnimationLength, !1, !1), kingSafe = v.isKingSafe(r.colour, u);
            var v = this.cloneBoard();
            if (v.makeMove(u, v.boardPieces[a][n], !1, this.moveAnimationLength, !1, !1), kingSafe = this.isKingSafe(r.colour, u), clog && console.log("kingSafe2:" + kingSafe), !kingSafe)return !1
        }
        if (e == o && t == i)return !0;
        if (0 > e || e > 7 || 0 > t || t > 7)return !1;
        if (null != this.boardPieces[e][t])return !1
    }
},Board.prototype.canMove = function (e, t, o, i, s) {
    var r = e.column, a = e.row;
    if (t > 7 || 0 > t || o > 7 || 0 > o)return clog && console.log("can't move coz out of bounds"), !1;
    var n = this.boardPieces[t][o], l = this.boardPieces[r][a];
    if (null == l)return !1;
    if (n && n.colour == l.colour)return !1;
    var h = !1;
    h = e.piece == ChessPiece.PAWN ? this.canMovePawn(r, a, t, o, i) : e.piece == ChessPiece.KNIGHT ? this.canMoveKnight(r, a, t, o) : this.canMoveStraight(r, a, t, o, e.piece, e), clog && console.log("moveOk:" + h);
    var c = !0;
    if (h && s) {
        var d = "";
        d += Move.columnToChar(r), d += String.fromCharCode("1".charCodeAt(0) + a), d += Move.columnToChar(t), d += String.fromCharCode("1".charCodeAt(0) + o);
        var u = this.createMoveFromString(d), v = this.cloneBoard();
        v.makeMove(u, v.boardPieces[r][a], !1, this.moveAnimationLength, !1, !1), c = v.isKingSafe(e.colour, u)
    }
    return h && c
},Board.prototype.is50MoveRule = function () {
    return this.halfMoveNumber >= 100
},Board.prototype.isCheckmate = function (e) {
    return !this.isKingSafe(this.toMove, e) && this.isKingMated(this.toMove, e)
},Board.prototype.isStalemate = function (e) {
    return this.isKingSafe(this.toMove, e) && 0 == this.getCandidateMoves(this.toMove, e, !0).length
},Board.prototype.isKingMated = function (e, t) {
    for (var o = null, i = 0; 8 > i; i++)for (var s = 0; 8 > s; s++) {
        var r = this.boardPieces[i][s];
        if (null != r && r.piece == ChessPiece.KING && r.colour == e) {
            o = r;
            break
        }
    }
    for (var a = [[1, 0], [1, 1], [1, -1], [-1, 0], [-1, 1], [-1, -1], [0, 1], [0, -1], [2, 0], [-2, 0]], r = o, n = 0; n < a.length; n++)if (this.canMove(r, r.column + a[n][0], r.row + a[n][1], t, !0))return !1;
    var l = this.getCandidateMoves(e, t, !0, !0);
    return l.length > 0 ? !1 : !0
},Board.prototype.getCandidateMoves = function (e, t, o, i) {
    for (var s = new Array, r = 0; 8 > r; r++)for (var a = 0; 8 > a; a++) {
        var n = this.boardPieces[r][a], l = [];
        if (n && n.colour == e) {
            switch (n.piece) {
                case ChessPiece.KING:
                    if (i)continue;
                    l = [[1, 0], [1, 1], [1, -1], [-1, 0], [-1, 1], [-1, -1], [0, 1], [0, -1], [2, 0], [-2, 0]];
                    break;
                case ChessPiece.KNIGHT:
                    l = [[2, 1], [2, -1], [-2, 1], [-2, -1], [1, 2], [1, -2], [-1, 2], [-1, -2]];
                    break;
                case ChessPiece.BISHOP:
                    for (var h = 0; 8 > h; h++)l.push([1 + h, 1 + h]), l.push([1 + h, -1 - h]), l.push([-1 - h, 1 + h]), l.push([-1 - h, -1 - h]);
                    break;
                case ChessPiece.QUEEN:
                    for (var h = 0; 8 > h; h++)l.push([1 + h, 0]), l.push([1 + h, 1 + h]), l.push([1 + h, -1 - h]), l.push([-1 - h, 0]), l.push([-1 - h, 1 + h]), l.push([-1 - h, -1 - h]), l.push([0, -1 - h]), l.push([0, 1 + h]);
                    break;
                case ChessPiece.ROOK:
                    for (var h = 0; 8 > h; h++)l.push([1 + h, 0]), l.push([-1 - h, 0]), l.push([0, -1 - h]), l.push([0, 1 + h]);
                    break;
                case ChessPiece.PAWN:
                    e == ChessPiece.BLACK ? (l = [[0, -1], [1, -1], [-1, -1]], 6 == a && l.push([0, -2])) : (l = [[0, 1], [1, 1], [-1, 1]], 1 == a && l.push([0, 2]))
            }
            for (var h = 0; h < l.length; h++)if (this.canMove(n, n.column + l[h][0], n.row + l[h][1], t, !0) && (s.push(new Move(n.column, n.row, n.column + l[h][0], n.row + l[h][1])), o))return s
        }
    }
    return s
},Board.prototype.isKingSafe = function (e, t) {
    for (var o = null, i = 0; 8 > i; i++)for (var s = 0; 8 > s; s++) {
        var r = this.boardPieces[i][s];
        if (null != r && r.piece == ChessPiece.KING && r.colour == e) {
            o = r;
            break
        }
    }
    for (var i = 0; 8 > i; i++)for (var s = 0; 8 > s; s++) {
        var r = this.boardPieces[i][s];
        if (null != r && r.colour != e && this.canMove(r, o.column, o.row, t, !1))return !1
    }
    return !0
},Board.prototype.freeBoardPieces = function (e) {
    if (this.boardPieces)for (var t = 0; 8 > t; t++) {
        for (var o = 0; 8 > o; o++)null != this.boardPieces[t][o] && (this.boardPieces[t][o].free(), this.boardPieces[t][o] = null);
        e && (this.boardPieces[t] = null)
    }
    e && (this.boardPieces = null)
},Board.prototype.freeBoard = function () {
    this.freeBoardPieces(!0), this.freeMoveArray()
},Board.prototype.freeMoveArray = function () {
    if (this.moveArray)for (var e = 0; e < this.moveArray.length; e++) {
        var t = this.moveArray[e];
        t && (t.freeMove(), this.moveArray[e] = null)
    }
},Board.prototype.cloneBoard = function () {
    var e = new Board;
    return e.boardName = this.boardName, e.cloned = !0, e.boardPieces = this.copyBoardPieces(!0), e.moveArray = this.copyMoveArray(!1), e.canCastleQueenSide = this.copyCastleQueenSide(), e.canCastleKingSide = this.copyCastleKingSide(), e.toMove = this.toMove, e.restrictedColourMovement = -1, e.opponentColour = this.opponentColour, e.outputWithoutDisplay = this.outputWithoutDisplay, e.isFlipped = this.isFlipped, e.isUserFlipped = this.isUserFlipped, e.ignoreFlipping = this.ignoreFlipping, e.reverseFlip = this.reverseFlip, e.moveAnimationLength = this.moveAnimationLength, e.moveNumber = this.moveNumber, e.halfMoveNumber = this.halfMoveNumber, e.startFen = this.startFen, e.boardImagePath = this.boardImagePath, e.dontUpdatePositionReachedTable = this.dontUpdatePositionReachedTable, e.prev_move = this.prev_move ? this.prev_move.clone() : null, e
},Board.prototype.copyCastleQueenSide = function () {
    return [this.canCastleQueenSide[0], this.canCastleQueenSide[1]]
},Board.prototype.copyCastleKingSide = function () {
    return [this.canCastleKingSide[0], this.canCastleKingSide[1]]
},Board.copyMoves = function (e, t, o) {
    var i = new Array;
    if (t) {
        if (e)for (var s = 0; s < e.length; s++) {
            var r = e[s], a = null;
            r && (a = r.clone(!0)), i[s] = a
        }
    } else e && e.length > 0 && (i = e.slice(0));
    if (o)for (var s = 0; s < e.length; s++)e[s].prev && "undefined" != typeof e[s].prev.index && (i[s].prev = i[e[s].prev.index]), e[s].next && "undefined" != typeof e[s].next.index && (i[s].next = i[e[s].next.index]);
    return i
},Board.prototype.copyMoveArray = function (e) {
    return Board.copyMoves(this.moveArray, e)
},Board.prototype.copyBoardPieces = function (e) {
    for (var t = Board.createBoardArray(), o = 0; 8 > o; o++)for (var i = 0; 8 > i; i++)t[o][i] = null != this.boardPieces[o][i] ? e ? this.boardPieces[o][i].makeLightWeight() : this.boardPieces[o][i].copyPiece() : null;
    return t
},Board.prototype.createPiece = function (e, t, o) {
    return o ? new LightweightChessPiece(null, e, t, this) : new ChessPiece(this.getPieceDiv(), e, t, this)
},Board.prototype.restoreCastling = function (e) {
    this.canCastleKingSide = e.kingSide, this.canCastleQueenSide = e.queenSide
},Board.prototype.saveCastling = function () {
    var e = [this.canCastleQueenSide[0], this.canCastleQueenSide[1]], t = [this.canCastleKingSide[0], this.canCastleKingSide[1]];
    return {queenSide: e, kingSide: t}
};
var firstLightProf = !0, firstHeavyProf = !0;
Board.prototype.setupFromFenLightweight = function (e, t, o, i, s) {
    var r = !1;
    r && console.profile("setupFromFenLight"), this.setupFromFenGeneric(e, t, o, !0, i, s), r && console.profileEnd()
}, Board.prototype.setupFromFenHeavyWeight = function (e, t, o, i, s) {
    var r = !1;
    r && console.profile("setupFromFenHeavy"), this.lastFromSquare && YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), this.lastToSquare && YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), this.setupFromFenGeneric(e, t, o, !1, i, s), r && console.profileEnd()
}, Board.prototype.setupFromFen = function (e, t, o, i, s, r) {
    this.positionsSeen = [], i ? this.setupFromFenLightweight(e, t, o, s, r) : this.setupFromFenHeavyWeight(e, t, o, s, r)
}, Board.prototype.setupFromFenGeneric = function (e, t, o, i, s, r) {
    ctime && console.time("setupFromFen" + i), this.oldSelectedSquare && YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square"), this.oldSelectedSquare = null, this.oldSelectedPiece = null, this.settingUpPosition = !0;
    var a = e.split(" "), n = a[0].split("/");
    this.halfMoveNumber = parseInt(a[4]), this.moveNumber = 2 * parseInt(a[5]);
    var l = 0, h = 8;
    this.uptoId = 0, this.board_xy = null;
    var c = a[2], d = null;
    if (this.canCastleQueenSide = [!1, !1], this.canCastleKingSide = [!1, !1], "-" != c && (c.indexOf("K") >= 0 && (this.canCastleKingSide[ChessPiece.WHITE] = !0), c.indexOf("Q") >= 0 && (this.canCastleQueenSide[ChessPiece.WHITE] = !0), c.indexOf("k") >= 0 && (this.canCastleKingSide[ChessPiece.BLACK] = !0), c.indexOf("q") >= 0 && (this.canCastleQueenSide[ChessPiece.BLACK] = !0)), r && (this.startMoveNum = this.moveNumber), "w" == a[1] ? (r && this.startMoveNum--, this.toMove = ChessPiece.WHITE, this.opponentColour = ChessPiece.WHITE, this.isFlipped = !1, this.moveNumber--) : (this.toMove = ChessPiece.BLACK, this.opponentColour = ChessPiece.BLACK, this.isFlipped = !0), s) {
        var u = a[3];
        if ("-" != u && 2 == u.length) {
            var v = u[0], m = parseInt(u[1]);
            d = this.createMoveFromString(3 == m ? v + "2" + v + "4" : v + "7" + v + "5"), d.prevMoveEnpassant = !0, this.prev_move = d
        }
    }
    t && (this.toMove = ChessPiece.BLACK == this.toMove ? ChessPiece.WHITE : ChessPiece.BLACK, this.isFlipped = !this.isFlipped), o && (this.isFlipped = !0), this.reverseFlip && (this.isFlipped = !this.isFlipped), this.ignoreFlipping && (this.isFlipped = !1), this.isUserFlipped && (this.isFlipped = !this.isFlipped), this.updateToPlay(), this.setupPieceDivs();
    for (var p = 0; 8 > p; p++)for (var g = 0; 8 > g; g++)this.boardPieces[p][g] = null;
    for (var p = 0; 8 > p; p++) {
        var f = n[p];
        h--, l = 0;
        for (var g = 0; g < f.length; g++) {
            var b = f.charAt(g), C = f.charCodeAt(g), y = C - "0".charCodeAt(0);
            if (y > 0 && 9 > y)for (; y--;) {
                {
                    this.boardPieces[l][h]
                }
                this.boardPieces[l][h] = null, l++
            } else {
                var M = (b + "").toLowerCase().charAt(0), O = ChessPiece.WHITE;
                M == b && (O = ChessPiece.BLACK);
                var P;
                switch (M) {
                    case"k":
                        P = this.createPiece(O, ChessPiece.KING, i);
                        break;
                    case"q":
                        P = this.createPiece(O, ChessPiece.QUEEN, i);
                        break;
                    case"r":
                        P = this.createPiece(O, ChessPiece.ROOK, i);
                        break;
                    case"b":
                        P = this.createPiece(O, ChessPiece.BISHOP, i);
                        break;
                    case"n":
                        P = this.createPiece(O, ChessPiece.KNIGHT, i);
                        break;
                    case"p":
                        P = this.createPiece(O, ChessPiece.PAWN, i);
                        break;
                    default:
                        alert("unknown piece letter:" + M + " for fen:" + e)
                }
                (isGecko || isOpera) && (P.setPosition(l, h, !1, null, this.moveAnimationLength), P.setVisible(!0)), this.boardPieces[l][h] = P, this.pieces[this.uptoPiece] = P, this.pieces[this.uptoPiece].column = l, this.pieces[this.uptoPiece].row = h, this.uptoPiece++, l++
            }
        }
    }
    if (!isGecko)for (var p = 0; p < this.uptoPiece; p++)this.pieces[p].setPosition(this.pieces[p].column, this.pieces[p].row, !1, null, 0);
    if (!i)for (var p = 0; p < this.uptoPiece; p++)this.pieces[p].setVisible(!0);
    i || this.createBoardCoords(), this.settingUpPosition = !1, ctime && console.timeEnd("setupFromFen" + i)
}, Board.prototype.resetMoveListScrollPosition = function () {
    var e = this.movesDisplay.getMovesDisplay();
    if (e) {
        var t = new YAHOO.util.Scroll(e, {scroll: {to: [0, 0]}}, 0);
        t.animate()
    }
}, Board.prototype.changePieceSet = function (e, t) {
    if (!this.showedIE6Warning) {
        var o = _js("Depending on your browser you may need to reload the<br/> page for piece size changes to properly take effect.");
        alert(o.replace("<br/>", "\n"))
    }
    if (this.showedIE6Warning = !0, check_bad_msie()) {
        if (!this.showedIE6Warning) {
            var o = _js("Internet Explorer version 6 does not support dynamic piece size changes.<br/> Please reload page to view new settings.");
            alert(o.replace("<br/>", "\n"))
        }
        return void(this.showedIE6Warning = !0)
    }
    this.pieceSize;
    this.pieceSet = e, this.pieceSize = t;
    var i = YAHOO.util.Dom.get(this.boardName + "-boardBorder"), s = 0;
    this.showCoordinates && (s = 15), i.className = "", YAHOO.util.Dom.addClass(i, "ct-board-border" + this.squareColorClass), YAHOO.util.Dom.setStyle(i, "width", 8 * this.pieceSize + s + "px"), YAHOO.util.Dom.setStyle(i, "height", 8 * this.pieceSize + s + "px");
    var r = YAHOO.util.Dom.get("ctb-" + this.boardName);
    YAHOO.util.Dom.setStyle(r, "width", 8 * this.pieceSize + "px"), YAHOO.util.Dom.setStyle(r, "height", 8 * this.pieceSize + "px");
    for (var a = "ct-white-square" + this.squareColorClass, n = 7; n >= 0; n--) {
        for (var l = 0; 8 > l; l++) {
            var h = this.getBoardDivFromId(this.boardName + "-s" + l + n);
            h.className = "", YAHOO.util.Dom.addClass(h, a), YAHOO.util.Dom.setStyle(h, "width", this.pieceSize + "px"), YAHOO.util.Dom.setStyle(h, "height", this.pieceSize + "px");
            var c = (l + 1) * (n + 1) % 19 / 19 * 100, d = (65 - (l + 1) * (n + 1)) % 19 / 19 * 100;
            YAHOO.util.Dom.setStyle(h, "background-position", c + "% " + d + "%"), a = a == "ct-black-square" + this.squareColorClass ? "ct-white-square" + this.squareColorClass : "ct-black-square" + this.squareColorClass
        }
        a = a == "ct-black-square" + this.squareColorClass ? "ct-white-square" + this.squareColorClass : "ct-black-square" + this.squareColorClass
    }
    for (var n = 0; 8 > n; n++)for (var l = 0; 8 > l; l++) {
        var u = this.boardPieces[n][l];
        if (u) {
            if (u.icon = get_image_str(ChessPiece.pieceIconNames[u.colour][u.piece], u.board.boardImagePath, u.board.pieceSet, u.board.pieceSize, u.board.addVersion), YAHOO.util.Event.isIE || isOpera) {
                var v = u.div;
                v.innerHTML = '<img src="' + u.icon + '"/>';
                var m = v.firstChild;
                isOpera || fix_ie_png(m)
            } else YAHOO.util.Dom.setStyle([u.div], "backgroundImage", "url(" + u.icon + ")"), YAHOO.util.Dom.setStyle([u.div], "background-repeat", "no-repeat");
            YAHOO.util.Dom.setStyle([u.div], "height", this.pieceSize + "px"), YAHOO.util.Dom.setStyle([u.div], "width", this.pieceSize + "px"), YAHOO.util.Dom.setStyle([u.div], "left", ""), YAHOO.util.Dom.setStyle([u.div], "top", "");
            var p = u.getNewXYPosition(u.column, u.row);
            YAHOO.util.Dom.setXY(u.div, p, !1)
        }
    }
    if (this.moveArray)for (var g = this.moveArray[0]; null != g;) {
        if (g.taken) {
            var u = g.taken;
            if (u.getNewXYPosition) {
                if (u.icon = get_image_str(ChessPiece.pieceIconNames[u.colour][u.piece], u.board.boardImagePath, u.board.pieceSet, u.board.pieceSize, u.board.addVersion), YAHOO.util.Event.isIE || isOpera) {
                    var v = u.div;
                    v.innerHTML = '<img src="' + u.icon + '"/>', YAHOO.util.Dom.setStyle([u.div], "position", "relative");
                    var m = v.firstChild;
                    isOpera || fix_ie_png(m)
                } else YAHOO.util.Dom.setStyle([u.div], "backgroundImage", "url(" + u.icon + ")"), YAHOO.util.Dom.setStyle([u.div], "background-repeat", "no-repeat");
                YAHOO.util.Dom.setStyle([u.div], "height", this.pieceSize + "px"), YAHOO.util.Dom.setStyle([u.div], "width", this.pieceSize + "px"), YAHOO.util.Dom.setStyle([u.div], "left", ""), YAHOO.util.Dom.setStyle([u.div], "top", "");
                var p = u.getNewXYPosition(u.column, u.row);
                YAHOO.util.Dom.setXY(u.div, p, !1)
            }
        }
        g = g.next
    }
    if (this.problem) {
        var f = YAHOO.util.Dom.get("body");
        f && YAHOO.util.Dom.setStyle(f, "min-width", 8 * this.pieceSize + s + 300 + 200 + 120 + "px")
    }
    this.createBoardCoords()
}, Board.prototype.forwardMove = function (e) {
    if (!this.disableNavigation) {
        if (this.blockFowardBack || this.deferredBlockForwardBack)return void(clog && console.log("returning early from forward due to block forward on"));
        var t = !1;
        if (this.tactics && this.tactics.problemActive)return void(clog && console.log("not forwarding, tactic is active"));
        if (this.blockForwardBack = !0, this.currentMove && !this.currentMove.atEnd)if (move = this.currentMove, move ? clog && console.log("forward move:" + move.output()) : clog && console.log("forward move with currentmove null"), move.endNode)clog && console.log("calling processendgame from forward move"), t || this.problem.processEndgame("", !0), this.toggleToMove(), this.updateToPlay(); else {
            clog && console.log("forwarding move:" + move.output());
            var o = null;
            piece = this.boardPieces[move.fromColumn][move.fromRow], move.promotion && (o = move.promotion, piece.prePromotionColumn = null, piece.prePromotionRow = null), this.updatePiece(piece, move.toColumn, move.toRow, !0, !0, !1, o, !0), this.toggleToMove(), this.updateToPlay();
            var i = this.currentMove;
            clog && console.log(i ? "after forward curmove:" + i.output() : "after forward cur move null");
            for (var s = 0; s < this.registeredForwardMovePostUpdateListeners.length; s++) {
                this.registeredForwardMovePostUpdateListeners[s].forwardMovePostUpdateCallback(move)
            }
        } else {
            clog && console.log("already at end");
            for (var s = 0; s < this.registeredForwardAtEndListeners.length; s++) {
                this.registeredForwardAtEndListeners[s].forwardAtEndCallback()
            }
        }
        this.blockForwardBack = !1
    }
}, Board.prototype.setupEventHandlers = function () {
    this.tlf = 0, YAHOO.util.Event.addListener(document, "blur", this.lostFocus, this, !0), this.avoidMouseoverActive || YAHOO.util.Event.addListener(this.boardName + "-container", "mouseover", function (e) {
        activeBoard = this
    }, this, !0), YAHOO.util.Event.addListener(this.boardName + "-container", "click", this.selectDestSquare, this, !0);
    var e = "keydown";
    isGecko && (e = "keypress"), YAHOO.util.Event.addListener(document, e, function (e) {
        var t = e.target ? e.target : e.srcElement;
        if (t.form)return !0;
        var o = t.tagName.toLowerCase();
        switch (o) {
            case"input":
            case"textarea":
            case"select":
                return !0
        }
        if (activeBoard != this)return !0;
        switch (YAHOO.util.Event.getCharCode(e)) {
            case 37:
                this.backMove();
                break;
            case 39:
                this.forwardMove();
                break;
            case 32:
                var i = this.spaceBar();
                return i || YAHOO.util.Event.preventDefault(e), i
        }
        return !0
    }, this, !0), YAHOO.util.Event.addListener(this.boardName + "-forward", "click", this.forwardMove, this, !0), YAHOO.util.Event.addListener(this.boardName + "-back", "click", this.backMove, this, !0), YAHOO.util.Event.addListener(this.boardName + "-start", "click", this.gotoStart, this, !0), YAHOO.util.Event.addListener(this.boardName + "-end", "click", this.gotoEnd, this, !0), YAHOO.util.Event.addListener(this.boardName + "-play", "click", this.playMoves, this, !0), YAHOO.util.Event.addListener(this.boardName + "-stop", "click", this.stopPlayingMoves, this, !0), this.r && (YAHOO.util.Event.addListener(this.boardName + "-analyse", "click", this.analysePosition, this, !0), YAHOO.util.Event.addListener(this.boardName + "-showfen", "click", this.showBoardFen, this, !0)), this.canPasteFen && YAHOO.util.Event.addListener(this.boardName + "-pastefen", "click", this.pasteFen, this, !0), this.g2 && YAHOO.util.Event.addListener(this.boardName + "-playcomp", "click", this.playComp, this, !0)
}, Board.prototype.addFlipListener = function (e) {
    this.registeredFlipListeners.push(e)
}, Board.prototype.addSpaceListener = function (e) {
    this.registeredSpaceListeners.push(e)
}, Board.prototype.flipBoard = function () {
    this.isUserFlipped = !this.isUserFlipped, this.isFlipped = !this.isFlipped, this.redrawBoard(), this.updateToPlay();
    for (var e = 0; e < this.registeredFlipListeners.length; e++)this.registeredFlipListeners[e].boardFlipped(this)
}, Board.prototype.spaceBar = function () {
    for (var e = !0, t = 0; t < this.registeredSpaceListeners.length; t++)e = this.registeredSpaceListeners[t].spacePressed(this);
    return e
}, Board.prototype.lostFocus = function () {
    this.tlf++
}, Board.prototype.redrawBoard = function () {
    for (var e = 0; 8 > e; e++)for (var t = 0; 8 > t; t++) {
        var o = this.boardPieces[e][t];
        if (o) {
            var i = o.getNewXYPosition(o.column, o.row);
            YAHOO.util.Dom.setXY(o.div, i, !1)
        }
    }
    if (this.moveArray)for (var s = this.moveArray[0]; null != s;) {
        if (s.taken) {
            var o = s.taken;
            if (o.getNewXYPosition) {
                var i = o.getNewXYPosition(o.column, o.row);
                YAHOO.util.Dom.setXY(o.div, i, !1)
            }
        }
        s = s.next
    }
    if (this.createBoardCoords(), this.oldSelectedSquare && YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square"), this.oldSelectedSquare = null, this.oldSelectedPiece = null, this.highlightFromTo) {
        if (this.isFlipped)var r = YAHOO.util.Dom.get(this.boardName + "-s" + (7 - this.lastFromColumn) + (7 - this.lastFromRow)), a = YAHOO.util.Dom.get(this.boardName + "-s" + (7 - this.lastToColumn) + (7 - this.lastToRow)); else var r = YAHOO.util.Dom.get(this.boardName + "-s" + this.lastFromColumn + this.lastFromRow), a = YAHOO.util.Dom.get(this.boardName + "-s" + this.lastToColumn + this.lastToRow);
        this.updateFromTo(r, a, this.lastFromRow, this.lastFromColumn, this.lastToRow, this.lastToColumn)
    }
}, Board.prototype.getMaxMoveNumber = function (e) {
    var t = this.getMaxPly(e);
    return t > 0 ? parseInt((t + 1) / 2) : 0
}, Board.prototype.getMaxPly = function (e) {
    var t = null;
    if (e) {
        if (!this.currentMove)return 0;
        if (t = this.currentMove, t.atEnd)return t.prev ? t.prev.moveNum : 0
    } else this.moveArray && (t = this.moveArray[0]);
    if (!t)return 0;
    for (; null != t;) {
        if (t.atEnd)return t.prev ? t.prev.moveNum : 0;
        t = t.next
    }
    return 0
}, Board.fenPositionOnly = function (e) {
    var t = e.split(" ");
    return t[0] + " " + t[1]
}, Board.fenStripMoveClock = function (e) {
    var t = e.split(" ");
    return t[0] + " " + t[1] + " " + t[2] + " " + t[3]
}, Board.fenSamePosition = function (e, t, o) {
    if (!e || !t)return !1;
    var i = null, s = null;
    return o ? (i = Board.fenPositionOnly(e), s = Board.fenPositionOnly(t)) : (i = Board.fenStripMoveClock(e), s = Board.fenStripMoveClock(t)), i == s
}, Board.prototype.findFen = function (e, t, o, i) {
    var s = this.findFen2(e, t, o, !0);
    if (s.move)return s.move;
    if (i) {
        if (s.clockStrip)return s.clockStrip;
        if (s.fullStrip)return s.fullStrip
    }
    return null
}, Board.prototype.findFen2 = function (e, t, o, i) {
    var s = t.cloneBoard(), r = Object(), a = null, n = null;
    r.move = null, i && s.gotoMoveIndex(-1, !0, !0, !0, !0);
    for (var l = null; e;) {
        var h = s.boardToFen();
        if (h == o)return r.move = l, r.clockStrip = null, r.fullStrip = null, r;
        if (Board.fenSamePosition(o, h) ? a = l : Board.fenSamePosition(o, h, !0) && (n = l), e.atEnd)break;
        if (e.vars && e.vars.length > 0)for (var c = 0; c < e.vars.length; c++) {
            var d = this.findFen2(e.vars[c], s, o, !1);
            if (d) {
                if (d.move)return d;
                d.clockStrip ? a = d.clockStrip : d.fullStrip && (n = d.fullStrip)
            }
        }
        clog && console.log("about to make mv:" + e.output() + " fen:" + s.boardToFen()), s.makeMove(e, s.boardPieces[e.fromColumn][e.fromRow], !1, this.moveAnimationLength, !1, !1), clog && console.log("finished making mv"), l = e, e = e.next, clog && console.log("toMove:" + s.toMove), s.setCurrentMove(e), s.toggleToMove()
    }
    return a && (r.clockStrip = a), n && (r.fullStrip = n), r
}, Board.prototype.gotoFen = function (e, t) {
    clog && console.log("about to find fen for:" + e);
    var o = this.findFen(this.moveArray[0], this, e, t);
    o ? (clog && console.log("found move:" + o.output() + " for fen:" + e), this.gotoMoveIndex(o.index)) : clog && console.log("didn't find move for fen:" + e)
}, Board.prototype.getMaxMoveIndex = function () {
    return this.moveArray.length - 1
}, Board.prototype.gotoMoveIndex = function (e, t, o, i, s) {
    clog && console.log("going to move index:" + e);
    var r = !o;
    if (!(!this.moveArray || this.moveArray.length <= e || -1 == e && 0 == this.moveArray.length)) {
        var a = this.boardName + "-piecestaken", n = YAHOO.util.Dom.get(a);
        if (n && (n.innerHTML = ""), -1 != e) {
            var l = new Array, h = this.moveArray[e];
            clog && h && (console.log("gotomoveindex move:" + h.output()), h.next && console.log("gotomoveindex move.next:" + h.next.output()), h.prev && console.log("gotomoveindex move.prev:" + h.prev.output()));
            var c = 0;
            for (null != h.next ? this.setCurrentMove(h.next, t) : clog && console.log("move next null with move:" + h.output()); null != h && !h.dummy;)l[c++] = h, h = h.prev;
            var d = !1;
            this.prev_move && !this.prev_move.prevMoveEnpassant && (d = !0), this.setupFromFen(this.startFen, d, !1, !0), this.prev_move && !this.prev_move.prevMoveEnpassant && (clog && console.log("gotomoveindex prev_move:" + this.prev_move.output()), this.makeMove(this.prev_move, this.boardPieces[this.prev_move.fromColumn][this.prev_move.fromRow], !1, this.moveAnimationLength, !0, !0), this.updateToPlay());
            for (var u = c - 1; u >= 1; u--) {
                var h = l[u];
                this.makeMove(h, this.boardPieces[h.fromColumn][h.fromRow], !1, this.moveAnimationLength, !0, !1), this.toggleToMove()
            }
            t || this.convertPiecesFromLightWeight(e);
            var h = l[0];
            if (this.makeMove(h, this.boardPieces[h.fromColumn][h.fromRow], r, this.moveAnimationLength, !0, !0), this.toggleToMove(), this.updateToPlay(), t || this.setForwardBack(), !i)for (var u = 0; u < this.registeredGotoMoveIndexListeners.length; u++) {
                this.registeredGotoMoveIndexListeners[u].gotoMoveIndexCallback(e)
            }
        } else {
            var d = !1;
            if (this.prev_move && !this.prev_move.prevMoveEnpassant && (d = !0), this.setupFromFen(this.startFen, d, !1, s), this.prev_move && !this.prev_move.prevMoveEnpassant && (this.makeMove(this.prev_move, this.boardPieces[this.prev_move.fromColumn][this.prev_move.fromRow], !o, this.moveAnimationLength, !0, !0), this.updateToPlay()), this.moveArray && this.moveArray.length > 0 ? this.setCurrentMove(this.moveArray[0], t) : this.setCurrentMove(this.firstMove, t), t || this.setForwardBack(), !i)for (var u = 0; u < this.registeredGotoMoveIndexListeners.length; u++) {
                this.registeredGotoMoveIndexListeners[u].gotoMoveIndexCallback(e)
            }
        }
    }
}, Board.prototype.gotoStart = function (e) {
    this.disableNavigation || (this.lastFromSquare && YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), this.lastToSquare && YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), this.gotoMoveIndex(-1), this.problem && (this.currentMove && this.currentMove.bestMoves ? this.problem.showBestMoves(this.currentMove, this.currentMove.bestMoves, this.currentMove.correctMove, this.currentMove.wrongMove) : this.problem.clearBestMoves()))
}, Board.prototype.gotoEnd = function (e) {
    if (!this.disableNavigation) {
        clog && console.log("goto end called"), this.tactics && this.tactics.problemActive && (this.tactics.autoForward = !1, this.tactics.markProblem(!1, !1, "NULL", "NULL")), clog && console.log("jumping to start"), this.gotoMoveIndex(-1, !0, !0, !0);
        for (var t = 0; this.currentMove && null != this.currentMove.next;) {
            var o = this.currentMove;
            clog && console.log("going to end move:" + o.output()), this.makeMove(o, this.boardPieces[o.fromColumn][o.fromRow], !1, this.moveAnimationLength, !0, !0), t = o.index, this.toggleToMove(), this.setCurrentMove(o.next)
        }
        for (var i = 0; i < this.registeredGotoMoveIndexListeners.length; i++) {
            this.registeredGotoMoveIndexListeners[i].gotoMoveIndexCallback(t)
        }
    }
}, Board.prototype.gotoPly = function (e, t) {
    clog && console.log("goto ply called"), this.gotoMoveIndex(-1, !0, !0, !0);
    for (var o = 1, i = 0; e >= o && this.currentMove && null != this.currentMove.next;) {
        var s = this.currentMove;
        clog && console.log("going to end move:" + s.output()), this.makeMove(s, this.boardPieces[s.fromColumn][s.fromRow], !1, this.moveAnimationLength, !0, !0), i = s.index, this.toggleToMove(), this.setCurrentMove(s.next), o++
    }
    if (t)for (var r = 0; r < this.registeredGotoMoveIndexListeners.length; r++) {
        this.registeredGotoMoveIndexListeners[r].gotoMoveIndexCallback(i)
    }
}, Board.prototype.playMove = function (e) {
    if (!e.keepPlayingMoves || !e.currentMove || !e.currentMove.next) {
        var t = YAHOO.util.Dom.get(this.boardName + "-play");
        return t.src = this.boardImagePath + "/images/control_play_blue" + this.getVersString() + ".gif", void(e.keepPlayingMoves = !1)
    }
    e.forwardMove(), setTimeout(function () {
        e.playMove(e)
    }, e.pauseBetweenMoves)
}, Board.prototype.insertLineToMoveIndexPosition = function (e, t, o, i, s) {
    var i = Board.copyMoves(i, !0, !0), r = null;
    if (!this.moveArray || 0 == this.moveArray.length || null == this.moveArray[0] || this.moveArray[0].atEnd || t == this.startFen)r = null, clog && console.log("no moves or initial position, using first move"); else if (clog && console.log("calling find fen...."), e >= 0 && (r = this.moveArray[e]), r || (r = this.findFen(this.moveArray[0], this, t, !1)), clog && console.log("finished calling find fen"), !r)return;
    var a = -1;
    this.currentMove && this.currentMove.prev && (a = this.currentMove.prev.index), o && (i[0].beforeComment = o), clog && console.log(r ? "mv:" + r.output() + " mv next:" + r.next + " oldCurrentMoveIndex:" + a : "mv: null oldCurrentMoveIndex:" + a);
    var n = null, l = null;
    r && r.next && !r.next.atEnd ? l = r.next : n = r, r ? this.gotoMoveIndex(r.index) : this.moveArray && this.moveArray.length > 0 ? (l = this.moveArray[0], l && (clog && console.log("variation parent from first move:" + l.output()), this.gotoMoveIndex(-1))) : this.currentMove = null, clog && console.log(this.currentMove ? "current move before insertline:" + this.currentMove.output() : "no current move before insertline"), clog && (console.log(l ? "var parent:" + l.output() : "var null"), console.log(n ? "move ins after:" + n.output() : "moveinsafter null")), this.insertMovesFromMoveList(i[0], !0, l, n, s), clog && console.log(this.currentMove ? "current move after insertline:" + this.currentMove.output() : "no current move after insertline"), this.gotoMoveIndex(a)
}, Board.prototype.getVersString = function () {
    var e = ".vers" + SITE_VERSION;
    return this.addVersion || (e = ""), e
}, Board.prototype.playMoves = function (e) {
    if (!this.disableNavigation) {
        this.keepPlayingMoves = !0;
        var t = YAHOO.util.Dom.get(this.boardName + "-play");
        t.src = this.boardImagePath + "/images/disabled_control_play_blue" + this.getVersString() + ".gif", this.playMove(this)
    }
}, Board.prototype.stopPlayingMoves = function (e) {
    this.keepPlayingMoves = !1
}, Board.prototype.pasteFen = function (e) {
    for (var t = 0; t < this.registeredPasteFenClickedListeners.length; t++) {
        this.registeredPasteFenClickedListeners[t].pasteFenClickedCallback()
    }
}, Board.prototype.playComp = function (e) {
    window.open("/play-computer/" + this.boardToFen())
}, Board.prototype.showBoardFen = function (e) {
    var t = this.boardToFen(), o = new YAHOO.widget.SimpleDialog("fenDialog", {
        fixedcenter: !1,
        visible: !0,
        draggable: !0,
        constraintoviewport: !1,
        buttons: [{id: "linkbutton4", text: "Test"}, {
            text: _js("Ok"), handler: function () {
                o.hide()
            }, isDefault: !0
        }]
    });
    o.setHeader(_js("Position FEN")), o.setBody('<textarea class="showPgn" id="fenText" rows="1" readonly="true" cols="' + (t.length + 9) + '">' + t + "</textarea>"), o.render(document.body), o.setFooter('<span id="copyToComment"></span><span id="fenok"></span>'), o.center();
    var i = this;
    if (this.problem && this.problem.comments) {
        new YAHOO.widget.Button({
            type: "button",
            label: _js("Copy To Comment"),
            container: "fenok",
            onclick: {
                fn: function () {
                    i.copyFenToComment(t, Board.COPY_COMMENT_PROBLEM), o.hide()
                }
            }
        })
    }
    if (this.gameComments) {
        new YAHOO.widget.Button({
            type: "button",
            label: _js("Copy To Game Comment"),
            container: "fenok",
            onclick: {
                fn: function () {
                    i.copyFenToComment(t, Board.COPY_COMMENT_GAME), o.hide()
                }
            }
        })
    }
    if (this.playerComments) {
        new YAHOO.widget.Button({
            type: "button",
            label: _js("Copy To Player Comment"),
            container: "fenok",
            onclick: {
                fn: function () {
                    i.copyFenToComment(t, Board.COPY_COMMENT_PLAYER), o.hide()
                }
            }
        })
    }
    if (this.openingComments) {
        new YAHOO.widget.Button({
            type: "button",
            label: _js("Copy To Opening Comment"),
            container: "fenok",
            onclick: {
                fn: function () {
                    i.copyFenToComment(t, Board.COPY_COMMENT_OPENING), o.hide()
                }
            }
        })
    }
    new YAHOO.widget.Button({
        type: "button", label: _js("Ok"), container: "fenok", onclick: {
            fn: function () {
                o.hide()
            }
        }
    })
}, Board.prototype.copyFenToComment = function (e, t) {
    switch (t) {
        case Board.COPY_COMMENT_PROBLEM:
            if (this.problem) {
                var o = !1, i = e.split(" ")[1], s = this.startFen.split(" ")[1];
                i == s && (o = !0), this.problem.comments.copyFenToComment(e, o)
            }
            break;
        case Board.COPY_COMMENT_GAME:
            this.gameComments.copyFenToComment(e);
            break;
        case Board.COPY_COMMENT_PLAYER:
            this.playerComments.copyFenToComment(e);
            break;
        case Board.COPY_COMMENT_OPENING:
            this.openingComments.copyFenToComment(e)
    }
}, Board.COPY_COMMENT_PROBLEM = 0, Board.COPY_COMMENT_PLAYER = 1, Board.COPY_COMMENT_GAME = 2, Board.COPY_COMMENT_OPENING = 3, Board.prototype.copyAnalysisToComment = function (e, t, o, i) {
    switch (i) {
        case Board.COPY_COMMENT_PROBLEM:
            this.problem && this.problem.comments.copyAnalysisToComment(e, t, o);
            break;
        case Board.COPY_COMMENT_GAME:
            this.gameComments.copyAnalysisToComment(e, t, o);
            break;
        case Board.COPY_COMMENT_PLAYER:
            this.playerComments.copyAnalysisToComment(e, t, o);
            break;
        case Board.COPY_COMMENT_OPENING:
            this.openingComments.copyAnalysisToComment(e, t, o)
    }
}, Board.squareColours = new Array(8);
for (var pCol = ChessPiece.BLACK, i = 0; 8 > i; i++) {
    Board.squareColours[i] = new Array(8);
    for (var j = 0; 8 > j; j++)Board.squareColours[i][j] = pCol, pCol = Board.invertToMove(pCol);
    pCol = Board.invertToMove(pCol)
}
Board.getSquareColour = function (e, t) {
    return Board.squareColours[e][t]
}, Board.prototype.isInsufficientMaterial = function (e) {
    function t() {
        return o > 0 || i > 0 ? !1 : s == r == 0 ? !0 : s == a && 0 == r ? !0 : r == n && 0 == s ? !0 : s == l && r == c ? !0 : s == h && r == d ? !0 : r == c && s == l ? !0 : s == d && s == h ? !0 : !1
    }

    for (var o = 0, i = 0, s = 0, r = 0, a = 0, n = 0, l = 0, h = 0, c = 0, d = 0, u = 0; 8 > u; u++)for (var v = 0; 8 > v; v++) {
        var m = this.boardPieces[u][v];
        m && (m.piece == ChessPiece.PAWN ? m.colour == ChessPiece.WHITE ? o++ : i++ : m.piece != ChessPiece.KING && (m.colour == ChessPiece.WHITE ? (s++, m.piece == ChessPiece.KNIGHT ? a++ : m.piece == ChessPiece.BISHOP && (Board.getSquareColour(u, v) == ChessPiece.WHITE ? l++ : h++)) : (r++, m.piece == ChessPiece.KNIGHT ? n++ : m.piece == ChessPiece.BISHOP && (Board.getSquareColour(u, v) == ChessPiece.WHITE ? c++ : d++))))
    }
    return -1 == e ? t() : e == ChessPiece.WHITE ? t() ? !0 : 0 == o && 0 == s ? !0 : s == l && r == c ? !0 : s == h && r == d ? !0 : s == a && 0 == r && 0 == i ? !0 : !1 : t() ? !0 : 0 == i && 0 == r ? !0 : r == c && s == l ? !0 : r == d && s == h ? !0 : r == n && 0 == s && 0 == o ? !0 : !1
}, Board.prototype.analysePosition = function (e) {
    window.parentBoard = this;
    var t = 8 * this.pieceSize + 450 + 50, o = 8 * this.pieceSize + 250, i = window.open("/windows/analyse.html", this.analysisWindowName, "width=" + t + ",height=" + o + ",resizable=1,scrollbars=1,location=0,copyhistory=0,status=0,toolbar=0,menubar=0");
    i.focus()
}, Board.prototype.backMove = function (e) {
    if (!this.disableNavigation && !this.blockFowardBack && !this.deferredBlockForwardBack) {
        var t = this.currentMove;
        if (!this.tactics || !this.tactics.problemActive) {
            if (this.blockForwardBack = !0, this.currentMove && null != this.currentMove.prev) {
                YAHOO.util.Dom.removeClass(this.lastFromSquare, "ct-from-square"), YAHOO.util.Dom.removeClass(this.lastToSquare, "ct-to-square"), this.lastFromRow = null, this.oldSelectedSquare && YAHOO.util.Dom.removeClass(this.oldSelectedSquare, "ct-source-square"),
                    this.oldSelectedSquare = null, this.oldSelectedPiece = null;
                var o = this.toMove;
                if (o = o == ChessPiece.WHITE ? ChessPiece.BLACK : ChessPiece.WHITE, !this.dontUpdatePositionReachedTable) {
                    var i = this.boardToUniqueFen(o);
                    this.positionsSeen[i] && this.positionsSeen[i]--
                }
                this.toggleToMove(), this.updateToPlay(), move = this.currentMove.prev, move && clog && console.log("backwards moving to prev move:" + move.output() + " from current move:" + this.currentMove.output()), this.setCurrentMove(move), piece = this.boardPieces[move.toColumn][move.toRow], piece || clog && console.log("got empty piece in backMove"), takenPiece = move.taken, this.board_xy = null, piece.setPosition(move.fromColumn, move.fromRow, !0, null, this.moveAnimationLength), this.boardPieces[move.fromColumn][move.fromRow] = piece, move.promotion && piece.changePiece("p"), piece.setVisible(!0), this.canCastleQueenSide[0] = move.preCastleQueenSide[0], this.canCastleQueenSide[1] = move.preCastleQueenSide[1], this.canCastleKingSide[0] = move.preCastleKingSide[0], this.canCastleKingSide[1] = move.preCastleKingSide[1], this.halfMoveNumber = move.preHalfMoveNumber;
                var s = !1;
                if (piece.piece == ChessPiece.KING && Math.abs(move.fromColumn - move.toColumn) > 1 && (s = !0), this.moveNumber--, this.moveNumber <= 0 && (this.moveNumber = 1), takenPiece && !s) {
                    this.board_xy = null;
                    var r = move.toColumn, a = move.toRow;
                    piece.piece == ChessPiece.PAWN && move.fromColumn != move.toColumn && takenPiece.enPassant && (a = move.fromRow, this.boardPieces[move.toColumn][move.toRow] = null), takenPiece.setPosition(r, a, !1, null, this.moveAnimationLength), this.boardPieces[r][a] = takenPiece, move.taken = null, this.processTaken(takenPiece, !1)
                } else this.boardPieces[move.toColumn][move.toRow] = null;
                if (s) {
                    var n, l, h = move.toRow;
                    move.fromColumn > move.toColumn ? (n = 0, l = 3) : (n = 7, l = 5);
                    var c = this.boardPieces[l][h];
                    c.setPosition(n, h, !0, null, this.moveAnimationLength), this.boardPieces[n][h] = c, this.boardPieces[l][h] = null
                }
                null != move && null != move.prev && move.prev.next != move && (move = move.prev.next, clog && console.log(move ? "moving backwards out of variation moving to:" + move.output() : "jumping out of variation to null move"));
                for (var d = 0; d < this.registeredBackMovePreCurrentListeners.length; d++) {
                    this.registeredBackMovePreCurrentListeners[d].backMovePreCurrentCallback(move, t)
                }
                this.setCurrentMove(move), this.setForwardBack()
            }
            this.blockForwardBack = !1
        }
    }
}, Board.prototype.getMovesToCurrent = function () {
    var e = [], t = [], o = this.currentMove;
    if (!o || !o.prev)return t;
    for (o = o.prev; o;)e.push(o), o = o.prev;
    for (var i = e.length - 1; i >= 0; i--)t.push(e[i].toMoveString());
    return t
}, Board.prototype.getAllMoves = function () {
    var e = null;
    if (e = this.moveArray && this.moveArray.length > 0 ? this.moveArray[0] : this.firstMove, !e)return [];
    for (var t = []; e && !e.atEnd;)t.push(e.toMoveString()), e = e.next;
    return t
}, Board.prototype.countPly = function () {
    var e = null;
    e = this.moveArray && this.moveArray.length > 0 ? this.moveArray[0] : this.firstMove;
    for (var t = 0; e && !e.atEnd;)t++, e = e.next;
    return t
}, Board.prototype.processTaken = function (e, t) {
    var o = this.boardName + "-piecestaken", i = YAHOO.util.Dom.get(o);
    if (i)if (t) {
        var s = get_image_str(ChessPiece.pieceIconNames[e.colour][e.piece], this.boardImagePath, this.pieceSet, this.pieceTakenSize, this.addVersion);
        i.innerHTML = i.innerHTML + '<img src="' + s + '"/>'
    } else {
        var r = i.innerHTML.split("<");
        i.innerHTML = "";
        for (var a = 1; a < r.length - 1; a++)i.innerHTML = i.innerHTML + "<" + r[a]
    }
}, Pool = function () {
    this.pool = new Array, this.count = -1, this.numGot = 0, this.numPut = 0
}, Pool.prototype.getObject = function () {
    var e = null;
    return this.count >= 0 && (this.numGot++, e = this.pool[this.count--]), e
}, Pool.prototype.putObject = function (e) {
    null != e && (this.numPut++, this.pool[++this.count] = e)
};
var boardPool = new Pool;
FenBoard = function (e, t) {
    "undefined" == typeof t.pieceSize && (t.pieceSize = 24), t.fenBoard = !0, t.dontOutputNavButtons = !0, t.avoidMouseoverActive = !0, this.chessapp = new ChessApp(t), this.chessapp.init(), this.chessapp.board.disableUpdateToPlay = !0, this.chessapp.board.setupFromFen(e, !1, !1, !1), this.board = this.chessapp.board, this.board.startFen = e
};