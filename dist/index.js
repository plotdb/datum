(function(){
  var datum;
  datum = {
    _sep: '-',
    format: function(it){
      if (!it || !Array.isArray(it) || (it[0] && !Array.isArray(it[0]))) {
        return 'db';
      }
      return 'sheet';
    },
    asSheet: function(obj){
      var k, sheet;
      if (this.format(obj) === 'sheet') {
        return obj;
      }
      if (Array.isArray(obj)) {
        obj = {
          head: (function(){
            var results$ = [];
            for (k in obj[0]) {
              results$.push(k);
            }
            return results$;
          }()),
          body: obj
        };
      }
      sheet = [obj.head].concat(obj.body.map(function(b){
        return obj.head.map(function(h){
          return b[h];
        });
      }));
      return sheet;
    },
    asDb: function(obj, name){
      var json, k;
      name == null && (name = 'unnamed');
      if (this.format(obj) === 'sheet') {
        json = {
          name: name,
          head: obj[0],
          body: obj.slice(1).map(function(b){
            return Object.fromEntries(obj[0].map(function(h, i){
              return [h, b[i]];
            }));
          })
        };
        return json;
      }
      if (Array.isArray(obj)) {
        return {
          name: name,
          head: (function(){
            var results$ = [];
            for (k in obj[0]) {
              results$.push(k);
            }
            return results$;
          }()),
          body: obj
        };
      }
      if (!obj.name) {
        obj.name = 'unnamed';
      }
      return obj;
    },
    concat: function(ds){
      var head, body, i$, to$, i;
      ds = ds.map(function(d){
        return data.asDb(d);
      });
      head = ds[0].head;
      body = [];
      for (i$ = 0, to$ = ds.length; i$ < to$; ++i$) {
        i = i$;
        body = body.concat(ds[i].body.map(fn$));
      }
      return {
        name: ds[0].name,
        head: head,
        body: body
      };
      function fn$(d){
        return Object.fromEntries(head.map(function(h){
          return [h, d[h]];
        }));
      }
    },
    join: function(d1, d2, jc){
      var sep, ref$, h1, h2, b1, b2, n1, n2, s1, s2, i$, to$, i, head, ret, body;
      sep = this._sep;
      ref$ = [d1, d2].map(function(d){
        return datum.asDb(d);
      }), d1 = ref$[0], d2 = ref$[1];
      ref$ = [d1.head, d2.head], h1 = ref$[0], h2 = ref$[1];
      ref$ = [d1.body, d2.body], b1 = ref$[0], b2 = ref$[1];
      ref$ = [d1.name || '1', d2.name || '2'], n1 = ref$[0], n2 = ref$[1];
      s1 = n1.split(sep);
      s2 = n2.split(sep);
      for (i$ = 0, to$ = s1.length; i$ < to$; ++i$) {
        i = i$;
        if (s1[i] !== s2[i]) {
          break;
        }
      }
      ref$ = [s1.slice(i).join(sep), s2.slice(i).join(sep)], n1 = ref$[0], n2 = ref$[1];
      if (!jc) {
        jc = h1.filter(function(h){
          return ~h2.indexOf(h);
        });
      }
      head = jc.concat(h1.filter(function(h){
        return !in$(h, jc);
      }).map(function(h){
        if (in$(h, h2)) {
          return n1 + "" + sep + h;
        } else {
          return h;
        }
      }), h2.filter(function(h){
        return !in$(h, jc);
      }).map(function(h){
        if (in$(h, h1)) {
          return n2 + "" + sep + h;
        } else {
          return h;
        }
      }));
      ret = b1.map(function(r1){
        var matched, ret;
        matched = b2.filter(function(r2){
          return !jc.filter(function(it){
            return r2[it] !== r1[it];
          }).length;
        });
        if (!matched.length) {
          matched = [{}];
        }
        ret = matched.map(function(r2){
          return Object.fromEntries(jc.map(function(h){
            return [h, r1[h]];
          }).concat(h1.filter(function(h){
            return !in$(h, jc);
          }).map(function(h){
            return [in$(h, h2) ? n1 + "" + sep + h : h, r1[h]];
          }), h2.filter(function(h){
            return !in$(h, jc);
          }).map(function(h){
            return [in$(h, h1) ? n2 + "" + sep + h : h, r2[h]];
          })));
        });
        return ret;
      });
      body = ret.reduce(function(a, b){
        return a.concat(b);
      }, []);
      return {
        name: d1.name || 'unnamed',
        head: head,
        body: body
      };
    },
    unjoin: function(data, cols){
      var head;
      data = this.asDb(data);
      return head = [].concat(data.head);
    },
    split: function(data, col){
      var head, idx, hash, ret, k, v;
      data = this.asDb(data);
      head = [].concat(data.head);
      if (!~(idx = head.indexOf(col))) {
        return data;
      }
      head.splice(idx, 1);
      hash = {};
      data.body.filter(function(d){
        var key$;
        return (hash[key$ = d[col]] || (hash[key$] = [])).push(d);
      });
      ret = [];
      for (k in hash) {
        v = hash[k];
        ret.push({
          name: (data.name || 'unnamed') + "" + this._sep + k,
          head: head,
          body: v
        });
      }
      return ret;
    },
    pivot: function(data, col, jc){
      var ds, base, i$, to$, i;
      ds = this.split(data, col);
      base = ds.splice(0, 1)[0];
      for (i$ = 0, to$ = ds.length; i$ < to$; ++i$) {
        i = i$;
        base = this.join(base, ds[i], jc);
      }
      return base;
    },
    unpivot: function(data, cols, name, order){
      var sep, hs, vals, tables, ret;
      cols == null && (cols = []);
      name == null && (name = "item");
      order == null && (order = 0);
      sep = this._sep;
      data = this.asDb(data);
      hs = data.head.filter(function(it){
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
            }).join(sep)
          ];
        });
        return {
          name: data.name,
          head: cols.concat([name], _hs.map(function(it){
            return it[1];
          })),
          body: data.body.map(function(b){
            return Object.fromEntries([[name, v]].concat((_cols.concat(_hs)).map(function(h){
              return [h[1], b[h[0]]];
            })));
          })
        };
      });
      ret = this.concat(tables);
      return ret;
    },
    group: function(data, col, agg){
      var hs, keys, ret;
      agg == null && (agg = {});
      data = this.asDb(data);
      hs = data.head.filter(function(it){
        return !(it === col) && agg[it] !== null;
      });
      keys = Array.from(new Set(data.body.map(function(b){
        return b[col];
      })));
      ret = keys.map(function(k){
        var list, ret;
        list = data.body.filter(function(it){
          return it[col] === k;
        });
        ret = Object.fromEntries(hs.map(function(h){
          var ls, ret;
          ls = list.map(function(l){
            return l[h];
          });
          ret = agg[h]
            ? agg[h](ls)
            : ls.length;
          return [h, ret];
        }));
        ret[col] = k;
        return ret;
      });
      return {
        head: [col].concat(hs),
        body: ret,
        name: data.name
      };
    },
    agg: {
      average: function(it){
        return it.reduce(function(a, b){
          return a + +b;
        }, 0) / (it.length || 1);
      },
      sum: function(it){
        return it.reduce(function(a, b){
          return a + +b;
        }, 0);
      },
      count: function(it){
        return it.length;
      },
      first: function(it){
        return it[0] || '';
      }
    }
  };
  if (typeof module != 'undefined' && module !== null) {
    module.exports = datum;
  } else if (typeof window != 'undefined' && window !== null) {
    window.datum = datum;
  }
  datum.type = {
    R: function(opt){
      var data, len;
      opt == null && (opt = {});
      data = opt.data.filter(function(it){
        return !(!it || (it + "").trim() === '');
      });
      len = data.filter(function(it){
        return !isNaN(parseFloat(it));
      }).length;
      return len / data.length;
    },
    O: function(opt){
      var data, hash, i$, to$, i, delta, k;
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
      return 1 / ((function(){
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
      opt == null && (opt = {});
      return 1 - datum.type.R(opt);
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
    bind: function(dataset, dimension){
      var datatypes, dims, k, v, i$, len$, dim, ts, j$, to$, i, t, k$, to1$, dt, ret;
      dataset == null && (dataset = []);
      dimension == null && (dimension = {});
      datatypes = datum.type.get(dataset);
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
            return "CONR".indexOf(t[i]);
          }));
        }), ma = ref$[0], mb = ref$[1];
        return ma - mb;
      });
      for (i$ = 0, len$ = dims.length; i$ < len$; ++i$) {
        dim = dims[i$];
        dim.bind = null;
        ts = dim.v.type || 'RNOC';
        for (j$ = 0, to$ = ts.length; j$ < to$; ++j$) {
          i = j$;
          t = ts[i];
          datatypes.sort(fn$);
          for (k$ = 0, to1$ = datatypes.length; k$ < to1$; ++k$) {
            i = k$;
            dt = datatypes[i];
            if (dt.types[t] < 0.5 || dt.used || (t === 'C' && dt.types.R > 0.5)) {
              continue;
            }
            dim.bind = dim.v.multiple ? [dt] : dt;
            dt.used = true;
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
            if (dt.types[t] < 0.5 || dt.used || (t === 'C' && dt.types.R > 0.5)) {
              continue;
            }
            dim.bind.push(dt);
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
        ret = (b[t] || 0) - (a[t] || 0);
        if (b[t] === a[t] && t === 'R') {
          return (a.O || 0) - (b.O || 0);
        }
        return ret;
      }
      function fn2$(it){
        var ref$;
        return ref$ = it.used, delete it.used, ref$;
      }
    }
  };
  function in$(x, xs){
    var i = -1, l = xs.length >>> 0;
    while (++i < l) if (x === xs[i]) return true;
    return false;
  }
}).call(this);
