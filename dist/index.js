/*
api change:
 shrink: ({cols, keep}) 
*/
(function(){
  var datum, itf, k, v;
  datum = function(o){
    o == null && (o = {});
    if (!(this instanceof datum)) {
      return o instanceof datum
        ? o
        : new datum(o);
    }
    this._sep = o.sep || '-';
    if (Array.isArray(o) || o.body) {
      this.from(o);
    } else if (o.data) {
      this.from(o.data);
    } else {
      this.clear();
    }
    return this;
  };
  itf = {
    clear: function(){
      return this._d = {
        h: [],
        b: [],
        n: ''
      };
    },
    clone: function(){
      return new datum(this.asSheet());
    },
    format: function(o){
      return !o || !Array.isArray(o) || (o[0] && !Array.isArray(o[0]))
        ? 'db'
        : o instanceof datum ? 'datum' : 'sheet';
    },
    _dedup: function(h){
      var c;
      c = {};
      h = h.map(function(n){
        while (c[n]) {
          n = n + "(" + (c[n]++) + ")";
        }
        c[n] = 1;
        return n;
      });
      return h;
    },
    from: function(d){
      var k, ref$, h, b, n, this$ = this;
      d == null && (d = {});
      this.clear();
      if (d instanceof datum) {
        this._d = JSON.parse(JSON.stringify(d._d));
      } else if (this.format(d) === 'sheet') {
        d = JSON.parse(JSON.stringify(d));
        d.map(function(r, i){
          if (i === 0) {
            return this$._d.h = r;
          } else {
            return this$._d.b.push(r);
          }
        });
      } else {
        d = JSON.parse(JSON.stringify(d));
        ref$ = Array.isArray(d)
          ? [
            (function(){
              var results$ = [];
              for (k in d[0] || {}) {
                results$.push(k);
              }
              return results$;
            }()), d
          ]
          : [d.head, d.body, d.name], h = ref$[0], b = ref$[1], n = ref$[2];
        this._d.n = n || '';
        this._d.h = h;
        this._d.b = b.map(function(_b){
          if (Array.isArray(_b)) {
            return _b;
          } else {
            return h.map(function(it){
              return _b[it];
            });
          }
        });
      }
      this._d.h = this._dedup(this._d.h);
      return this;
    },
    asSheet: function(){
      return JSON.parse(JSON.stringify([this._d.h].concat(this._d.b)));
    },
    asDb: function(){
      var h;
      this._d.h = h = this._dedup(this._d.h);
      return JSON.parse(JSON.stringify({
        name: this._d.n,
        head: this._d.h,
        body: this._d.b.map(function(b){
          return Object.fromEntries(b.map(function(d, i){
            return [h[i], d];
          }));
        })
      }));
    },
    name: function(){
      return this._d.n || '';
    },
    head: function(){
      return this._d.h;
    },
    body: function(){
      return this._d.b;
    },
    sep: function(it){
      if (arguments.length) {
        return this._sep = it;
      } else {
        return this._sep;
      }
    },
    concat: function(){
      var ds, hs, bs, body, i$, to$, i, ref$, h, b;
      ds = [this].concat(Array.from(arguments).map(function(it){
        return datum.from(it);
      }));
      hs = [];
      ds.map(function(d){
        return hs = hs.concat(d.head());
      });
      hs = Array.from(new Set(hs));
      bs = [];
      body = [];
      for (i$ = 0, to$ = ds.length; i$ < to$; ++i$) {
        i = i$;
        ref$ = [ds[i].head(), ds[i].body()], h = ref$[0], b = ref$[1];
        bs = bs.concat(b.map(fn$));
      }
      this._d.h = hs;
      this._d.b = bs;
      return this;
      function fn$(d, i){
        return hs.map(function(it){
          var j;
          if (~(j = h.indexOf(it))) {
            return d[j];
          } else {
            return undefined;
          }
        });
      }
    },
    shrink: function(arg$){
      var cols, keep, ref$, k, c, idx;
      cols = arg$.cols, keep = arg$.keep;
      ref$ = [keep != null && !keep ? false : true, cols], k = ref$[0], c = ref$[1];
      c = Array.isArray(c)
        ? c
        : [c];
      idx = this._d.h.map(function(h, i){
        var ref$;
        if (!(!k !== !(ref$ = in$(h, c)) && (k || ref$))) {
          return i;
        } else {
          return -1;
        }
      });
      this._d.h = this._d.h.filter(function(h, i){
        return in$(i, idx);
      });
      this._d.b = this._d.b.map(function(b){
        return b.filter(function(b, i){
          return in$(i, idx);
        });
      });
      return this;
    },
    rehead: function(m){
      this._d.h = this._dedup(this._d.h.map(function(h){
        return m[h] || h;
      }));
      return this;
    },
    split: function(arg$){
      var col, d, ref$, h, m, ds, i, i$, len$, b, key$, k, v;
      col = arg$.col;
      d = JSON.parse(JSON.stringify(this._d));
      ref$ = [d.h, {}, []], h = ref$[0], m = ref$[1], ds = ref$[2];
      if (!~(i = h.indexOf(col))) {
        return this.clone();
      }
      h.splice(i, 1);
      for (i$ = 0, len$ = (ref$ = d.b).length; i$ < len$; ++i$) {
        b = ref$[i$];
        (m[key$ = b[i]] || (m[key$] = [])).push(b);
        b.splice(i, 1);
      }
      for (k in m) {
        v = m[k];
        ds.push(new datum({
          head: h,
          body: v,
          name: (this._d.n ? this._d.n + '/' : '') + "" + k
        }));
      }
      return ds;
    },
    pivot: function(o){
      var col, joinCols, simpleHead, ds, ret;
      o == null && (o = {});
      col = o.col, joinCols = o.joinCols, simpleHead = o.simpleHead;
      if (!(simpleHead != null)) {
        simpleHead = false;
      }
      ds = this.split({
        col: col
      });
      ds = ds.map(function(d){
        return d.shrink({
          cols: col,
          keep: false
        });
      });
      ret = datum.join({
        ds: ds,
        joinCols: joinCols,
        simpleHead: simpleHead
      });
      this.from(ret);
      return this;
    },
    join: function(){
      var args, opt, ds, sep, joinCols, simpleHead, hs, bs, ns, ss, idx, i$, to$, i, j$, to1$, j, heads, k, rehead, hm, nhs, head, joinValues, body, list;
      args = Array.from(arguments);
      opt = args.filter(function(it){
        return it && (it.joinCols || it.ds);
      })[0] || {};
      ds = Array.isArray(opt.ds) ? opt.ds : args;
      ds = ds.map(function(it){
        if (it instanceof datum) {
          return it;
        } else if (Array.isArray(it) || it.body) {
          return datum.from(it);
        } else {
          return null;
        }
      }).filter(function(it){
        return it;
      });
      if (this instanceof datum) {
        ds = [this].concat(ds);
      }
      sep = ds[0].sep();
      joinCols = opt.joinCols, simpleHead = opt.simpleHead;
      hs = ds.map(function(it){
        return it._d.h;
      });
      bs = ds.map(function(it){
        return it._d.b;
      });
      ns = ds.map(function(d, i){
        return d.name() || (i + 1) + "";
      });
      ss = ns.map(function(it){
        return it.split(sep);
      });
      idx = -1;
      for (i$ = 0, to$ = ss[0].length; i$ < to$; ++i$) {
        i = i$;
        for (j$ = 1, to1$ = ss.length; j$ < to1$; ++j$) {
          j = j$;
          if (ss[j][i] !== ss[0][i]) {
            idx = i;
            break;
          }
        }
        if (idx >= 0) {
          break;
        }
      }
      if (idx < 0) {
        ns = ds.map(function(d, i){
          return (i + 1) + "";
        });
      } else {
        ns = ss.map(function(it){
          return it.slice(idx).join(sep);
        });
      }
      heads = {};
      hs.map(function(head){
        return head.map(function(h){
          return heads[h] = (heads[h] || 0) + 1;
        });
      });
      if (!joinCols) {
        joinCols = (function(){
          var results$ = [];
          for (k in hs) {
            results$.push(k);
          }
          return results$;
        }()).filter(function(it){
          return hs[it] === hs.length;
        });
      }
      rehead = function(n, h){
        if (simpleHead) {
          return n;
        }
        if (heads[h] > 1) {
          return n + "" + sep + h;
        }
        return h;
      };
      hm = hs.map(function(h, i){
        return Object.fromEntries(h.map(function(_h){
          return [_h, !in$(_h, joinCols) ? rehead(ns[i], _h) : _h];
        }));
      });
      nhs = hs.map(function(h, i){
        var nh;
        return nh = h.filter(function(_h){
          return !in$(_h, joinCols);
        }).map(function(_h){
          return rehead(ns[i], _h);
        });
      });
      head = ([joinCols].concat(nhs)).reduce(function(a, b){
        return a.concat(b);
      }, []);
      joinValues = {};
      bs.map(function(body, i){
        var head;
        head = hs[i];
        return body.map(function(b){
          var ret, index, i$, to$, j;
          ret = {};
          index = JSON.stringify(Object.fromEntries(joinCols.map(function(h){
            return [h, b[head.indexOf(h)]];
          })));
          for (i$ = 0, to$ = head.length; i$ < to$; ++i$) {
            j = i$;
            ret[hm[i][head[j]]] = b[j];
          }
          return (joinValues[index] || (joinValues[index] = [])).push(ret);
        });
      });
      body = [];
      for (k in joinValues) {
        list = joinValues[k];
        body.push(list.reduce(fn$, {}));
      }
      body = body.map(function(b){
        return head.map(function(h){
          return b[h];
        });
      });
      return datum.from({
        head: head,
        body: body,
        name: ds[0].name() || ''
      });
      function fn$(a, b){
        return import$(a, b);
      }
    },
    unpivot: function(opt){
      var cols, name, order, sep, body, hs, vals, tables, ret, this$ = this;
      opt == null && (opt = {});
      cols = opt.cols, name = opt.name, order = opt.order;
      cols = Array.isArray(cols)
        ? cols
        : [cols];
      cols = this._d.h.filter(function(it){
        return !in$(it, cols);
      });
      if (!name) {
        name = 'item';
      }
      if (!(order != null)) {
        order = 0;
      }
      sep = this._sep;
      body = this._d.b;
      hs = this._d.h.filter(function(it){
        return !in$(it, cols);
      }).map(function(it){
        return it.split(sep);
      });
      vals = Array.from(new Set(hs.map(function(it){
        return it[order];
      })));
      tables = vals.map(function(v){
        var _cols, _hs;
        _cols = cols.map(function(it){
          return [it, it];
        });
        _hs = hs.filter(function(it){
          return it[order] === v;
        }).map(function(it){
          return [
            it.join(sep), it.filter(function(d, i){
              return i !== order;
            }).join(sep) || 'value'
          ];
        });
        return datum.from({
          name: this$.name(),
          head: cols.concat([name], _hs.map(function(it){
            return it[1];
          })),
          body: body.map(function(b){
            return cols.map(function(c){
              return b[this$._d.h.indexOf(c)];
            }).concat([v], _hs.map(function(h){
              return b[this$._d.h.indexOf(h[0])];
            }));
          })
        });
      });
      ret = datum.concat(tables);
      this._d = ret._d;
      return this;
    },
    group: function(opt){
      var cols, groupFunc, agg, _agg, hs, idxs, keys, hash, newkeys, res$, k, body, this$ = this;
      opt == null && (opt = {});
      cols = opt.cols, groupFunc = opt.groupFunc;
      agg = opt.aggregator || {};
      _agg = {};
      cols = Array.isArray(cols)
        ? cols
        : [cols];
      hs = this._d.h.map(function(h, i){
        if (!in$(h, cols) && agg[h] !== null) {
          return i;
        } else {
          return -1;
        }
      }).filter(function(it){
        return it >= 0;
      });
      hs.map(function(i){
        return _agg[i] = agg[this$._d.h[i]];
      });
      idxs = cols.map(function(c){
        return this$._d.h.indexOf(c);
      });
      keys = Array.from(new Set(this._d.b.map(function(b){
        return JSON.stringify(Object.fromEntries(idxs.map(function(i){
          return [this$._d.h[i], b[i]];
        })));
      })));
      hash = {};
      keys.map(function(raw){
        var rkey, gkey, _gf, k, v;
        rkey = JSON.parse(raw);
        if (typeof groupFunc === 'function') {
          gkey = groupFunc(rkey);
        } else {
          _gf = groupFunc || {};
          gkey = {};
          for (k in rkey) {
            v = rkey[k];
            gkey[k] = typeof _gf[k] === 'function' ? _gf[k](v) : v;
          }
        }
        return (Array.isArray(gkey)
          ? gkey
          : [gkey]).map(function(k){
          k = JSON.stringify(k);
          if (!hash[k]) {
            hash[k] = new Set();
          }
          return hash[k].add(raw);
        });
      });
      res$ = [];
      for (k in hash) {
        res$.push(k);
      }
      newkeys = res$;
      body = newkeys.map(function(nk){
        var list, ret;
        list = Array.from(hash[nk]);
        nk = JSON.parse(nk);
        list = list.map(function(k){
          k = JSON.parse(k);
          return this$._d.b.filter(function(b){
            return !idxs.filter(function(i){
              return b[i] !== k[this$._d.h[i]];
            }).length;
          });
        }).reduce(function(a, b){
          return a.concat(b);
        }, []);
        ret = [];
        idxs.map(function(i){
          return ret.push(nk[this$._d.h[i]]);
        });
        hs.map(function(h, i){
          var ls;
          ls = list.map(function(l){
            return l[h];
          });
          return ret.push(_agg[h]
            ? _agg[h](ls)
            : ls.length);
        });
        return ret;
      });
      this.from({
        name: this._d.n,
        head: cols.concat(hs.map(function(i){
          return this$._d.h[i];
        })),
        body: body
      });
      return this;
    },
    trim: function(){
      var d, isEmpty;
      d = this._d.b.filter(function(r){
        return r.filter(function(it){
          return !(it === "" || it === null || !(it != null));
        }).length;
      });
      isEmpty = this._d.h.map(function(c, i){
        return !d.filter(function(r){
          return !(r[i] === "" || r[i] === null || r[i] == null);
        }).length;
      });
      this._d.h = this._d.h.filter(function(c, i){
        return !isEmpty[i];
      });
      this._d.b = d.map(function(r){
        return r.filter(function(c, i){
          return !isEmpty[i];
        });
      });
      return this;
    },
    transpose: function(){
      var d;
      d = [this._d.h].concat(this._d.b);
      d = this._d.h.map(function(r, i){
        return d.map(function(c, j){
          return c[i];
        });
      });
      this._d.h = d.splice(0, 1)[0];
      this._d.b = d;
      return this;
    }
  };
  datum.prototype = import$(Object.create(Object.prototype), itf);
  datum.from = function(d){
    if (d instanceof datum) {
      return d.clone();
    } else {
      return new datum(d);
    }
  };
  datum.format = itf.format;
  datum.join = function(o){
    return new datum().join(o);
  };
  datum.concat = function(ds){
    var ret;
    ds = arguments.length > 1 ? Array.from(arguments) : ds;
    ret = datum.from(ds[0]);
    ret.concat.apply(ret, ds.slice(1));
    return ret;
  };
  datum.agg = {
    average: function(it){
      return it.reduce(function(a, b){
        return a + (isNaN(+b)
          ? 0
          : +b);
      }, 0) / (it.length || 1);
    },
    sum: function(it){
      return it.reduce(function(a, b){
        return a + (isNaN(+b)
          ? 0
          : +b);
      }, 0);
    },
    count: function(it){
      return it.length;
    },
    first: function(it){
      return it[0] || '';
    }
  };
  for (k in itf) {
    v = itf[k];
    if (datum[k]) {
      continue;
    }
    fn$(k, v);
  }
  if (typeof module != 'undefined' && module !== null) {
    module.exports = datum;
  } else if (typeof window != 'undefined' && window !== null) {
    window.datum = datum;
  }
  datum.type = {
    R: function(opt){
      var data, len, r, o;
      opt == null && (opt = {});
      data = opt.data.filter(function(it){
        return !(!it || (it + "").trim() === '');
      });
      len = data.filter(function(it){
        return !isNaN(parseFloat(it));
      }).length;
      r = len / data.length;
      o = datum.type.O(opt);
      if (o === r || o > 0.9) {
        r = o * 0.99;
      }
      return r;
    },
    O: function(opt){
      var data, hash, i$, to$, i, delta, o, k;
      opt == null && (opt = {});
      data = [].concat(opt.data);
      data.sort(function(a, b){
        return b - a;
      });
      hash = {};
      for (i$ = 1, to$ = data.length; i$ < to$; ++i$) {
        i = i$;
        if (isNaN(data[i]) || isNaN(data[i - 1])) {
          hash[data[i] > data[i - 1]
            ? data[i] + ":" + data[i - 1]
            : data[i - 1] + ":" + data[i]] = true;
        } else {
          delta = data[i] - data[i - 1];
        }
        hash[delta] = true;
      }
      return o = 1 / ((function(){
        var results$ = [];
        for (k in hash) {
          results$.push(k);
        }
        return results$;
      }()).filter(function(it){
        return it !== '0';
      }).length || 2);
    },
    N: function(opt){
      var n, c;
      opt == null && (opt = {});
      n = 1 - datum.type.R(opt);
      c = datum.type.C(opt);
      if (c > 0.85) {
        n = c * 0.99;
      }
      return n;
    },
    C: function(opt){
      var len, maxlen, ret, ref$, ref1$, ref2$;
      opt == null && (opt = {});
      len = Array.from(new Set(opt.data)).length;
      maxlen = opt.data.length;
      ret = (ref$ = (ref1$ = 1 - ((ref2$ = len - 2) > 0 ? ref2$ : 0) / maxlen - 1 / maxlen) > 0 ? ref1$ : 0) < 1 ? ref$ : 1;
      if (datum.type.R(opt)) {
        ret = ret * 0.9;
      }
      return ret;
    },
    get: function(dataset){
      var ref$, head, body, type, i$, len$, key, d, list;
      ref$ = datum.asDb(dataset), head = ref$.head, body = ref$.body;
      type = [];
      for (i$ = 0, len$ = head.length; i$ < len$; ++i$) {
        key = head[i$];
        d = body.map(fn$);
        list = ['R', 'O', 'N', 'C'].map(fn1$);
        list.sort(fn2$);
        type.push({
          key: key,
          types: Object.fromEntries(list),
          type: list[0][0]
        });
      }
      return type;
      function fn$(it){
        return it[key];
      }
      function fn1$(t){
        return [
          t, datum.type[t]({
            data: d
          })
        ];
      }
      function fn2$(a, b){
        return b[1] - a[1];
      }
    },
    bind: function(dataset, dimension, datatypes){
      var dims, k, v, i$, len$, dim, ts, j$, to$, i, t, k$, to1$, dt, ret;
      dataset == null && (dataset = []);
      dimension == null && (dimension = {});
      if (!datatypes) {
        datatypes = datum.type.get(dataset);
      }
      dims = (function(){
        var ref$, results$ = [];
        for (k in ref$ = dimension) {
          v = ref$[k];
          results$.push({
            k: k,
            v: v
          });
        }
        return results$;
      }()).filter(function(it){
        return !it.v.passive;
      });
      dims.sort(function(a, b){
        var ret, ref$, ma, mb;
        ret = (a.v.priority || 100) - (b.v.priority || 100);
        if (ret !== 0) {
          return ret;
        }
        ref$ = [a.v.type || 'R', b.v.type || 'R'].map(function(t){
          return Math.min.apply(Math, (function(){
            var i$, to$, results$ = [];
            for (i$ = 0, to$ = t.length; i$ < to$; ++i$) {
              results$.push(i$);
            }
            return results$;
          }()).map(function(i){
            return "CONRI".indexOf(t[i]);
          }));
        }), ma = ref$[0], mb = ref$[1];
        return ma - mb;
      });
      for (i$ = 0, len$ = dims.length; i$ < len$; ++i$) {
        dim = dims[i$];
        dim.bind = null;
        ts = dim.v.type || 'RINOC';
        for (j$ = 0, to$ = ts.length; j$ < to$; ++j$) {
          i = j$;
          t = ts[i];
          datatypes.sort(fn$);
          for (k$ = 0, to1$ = datatypes.length; k$ < to1$; ++k$) {
            i = k$;
            dt = datatypes[i];
            if (!(dt.types[t] != null) || dt.types[t] < 0.5 || dt.used || (t === 'C' && dt.types.R > 0.5)) {
              continue;
            }
            dim.bind = dim.v.multiple ? [dt] : dt;
            dt.used = true;
            break;
          }
          if (dim.bind) {
            break;
          }
        }
      }
      for (i$ = 0, len$ = dims.length; i$ < len$; ++i$) {
        dim = dims[i$];
        if (!dim.v.multiple) {
          continue;
        }
        ts = dim.v.type || 'RNOC';
        for (j$ = 0, to$ = ts.length; j$ < to$; ++j$) {
          i = j$;
          t = ts[i];
          datatypes.sort(fn1$);
          for (k$ = 0, to1$ = datatypes.length; k$ < to1$; ++k$) {
            i = k$;
            dt = datatypes[i];
            if (!(dt.types[t] != null) || dt.types[t] < 0.5 || dt.used || (t === 'C' && dt.types.R > 0.5)) {
              continue;
            }
            (dim.bind || (dim.bind = [])).push(dt);
            dt.used = true;
          }
        }
      }
      ret = {};
      for (i$ = 0, len$ = dims.length; i$ < len$; ++i$) {
        dim = dims[i$];
        if (dim.bind) {
          ret[dim.k] = dim.bind;
          (Array.isArray(dim.bind)
            ? dim.bind
            : [dim.bind]).map(fn2$);
        }
      }
      return ret;
      function fn$(a, b){
        var ret;
        ret = (b.types[t] || 0) - (a.types[t] || 0);
        if (b.types[t] === a.types[t] && t === 'R') {
          return (a.types.O || 0) - (b.types.O || 0);
        }
        return ret;
      }
      function fn1$(a, b){
        var ret;
        ret = (b.types[t] || 0) - (a.types[t] || 0);
        if (b.types[t] === a.types[t] && t === 'R') {
          return (a.types.O || 0) - (b.types.O || 0);
        }
        return ret;
      }
      function fn2$(b){
        var ref$;
        if (dataset.unit) {
          b.unit = dataset.unit[b.key] || '';
        }
        return ref$ = b.used, delete b.used, ref$;
      }
    }
  };
  datum.sample = {
    C: ['books', 'business', 'education', 'entertainment', 'finance', 'food', 'games', 'health', 'lifestyle', 'medical', 'music', 'navigation', 'news', 'photography', 'productivity', 'social', 'network', 'sports', 'travel', 'utilities', 'weather'],
    N: ["The Perfect Storm", "Philadelphia Story", "Planet of the Apes", "Patton", "Pocahontas", "Pinoccio", "Quills", "Raiders of the Lost Ark", "Romeo and Juliet", "Snow White", "Shine", "Some Like It Hot", "Stardust", "Startrek", "The Seven Year Itch", "The Sound of Music", "Sabrina", "Sixth Sense", "The Silence of the Lambs", "Stargate", "Sunset Boulevard", "Superman"],
    generate: function(arg$){
      var count, binding, ref$, gen, idx, fields, k, v, u, keys, offset, i$, i, ret, hint, value, range, val, mod;
      count = arg$.count, binding = arg$.binding;
      ref$ = [
        {
          raw: [],
          binding: {}
        }, 0, count || 10
      ], gen = ref$[0], idx = ref$[1], count = ref$[2];
      if (!fields) {
        fields = {};
      }
      for (k in binding) {
        v = binding[k];
        u = Array.isArray(v)
          ? v
          : [v];
        keys = u.map(fn$);
        if (Array.isArray(v)) {
          gen.binding[k] = keys.map(fn1$);
        } else {
          gen.binding[k] = {
            key: (ref$ = fields[keys[0]]).key,
            name: ref$.name
          };
        }
      }
      offset = Math.round(100 * Math.random());
      for (i$ = 0; i$ < count; ++i$) {
        i = i$;
        ret = {};
        for (k in fields) {
          v = fields[k];
          hint = v.hint;
          value = (fn2$());
          ret[v.key] = value;
        }
        gen.raw.push(ret);
      }
      return gen;
      function fn$(d, i){
        var key, name;
        key = d.key || "field-" + idx;
        name = d.name || key;
        fields[idx] = {
          key: key,
          name: name,
          hint: d
        };
        idx = idx + 1;
        return idx - 1;
      }
      function fn1$(it){
        var ref$;
        return {
          key: (ref$ = fields[it]).key,
          name: ref$.name
        };
      }
      function fn2$(){
        var ref$, ref1$;
        switch (hint.type) {
        case 'R':
          range = hint.range || [0, 100];
          val = Math.random() * (range[1] - range[0]) + range[0];
          if (range[1] - range[0] < 1) {
            return val;
          } else {
            return Math.round(val);
          }
        case 'N':
          return datum.sample.N[i % datum.sample.N.length];
        case 'C':
          mod = (ref$ = hint.count != null
            ? hint.count
            : (ref$ = Math.round(count / 10)) > 4 ? ref$ : 4) < (ref1$ = datum.sample.C.length) ? ref$ : ref1$;
          return datum.sample.C[(hint.random ? Math.floor(Math.random() * count) : i) % mod];
        case 'O':
          return Math.floor(i / (hint.repeat != null ? hint.repeat : 1)) + (hint.offset != null ? hint.offset : offset);
        default:
          return "...";
        }
      }
    }
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function fn$(k, v){
    return datum[k] = function(d){
      var args, res$, i$, to$;
      res$ = [];
      for (i$ = 1, to$ = arguments.length; i$ < to$; ++i$) {
        res$.push(arguments[i$]);
      }
      args = res$;
      d = datum.format(d) === 'datum'
        ? d
        : datum.from(d);
      return v.apply(d, args);
    };
  }
}).call(this);
