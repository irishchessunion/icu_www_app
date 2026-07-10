window.ICU = window.ICU || {};

ICU.Maps = (function () {
  var DEFAULT_STYLE = 'https://tiles.openfreemap.org/styles/bright';

  // Shoes full country
  var DEFAULT_ZOOM = 5.5;
  var DEFAULT_CENTER = [-8.1, 53.5]; // [lng, lat]

  // Clusterer params
  var CLUSTER_SIZE = 40;
  var SHADOW_RADIUS = 16;
  var BALL_RADIUS = 12;
  var CENTER_OFFSET = 20;
  var CLUSTER_RADIUS = 40;
  var CLUSTER_MAX_ZOOM = 14;
  var CLUSTER_MIN_POINTS = 3;

  var MARKER_SIZE = [20, 25];
  // Cache for the icons
  var clusterIconCache = {};

  function buildClusterIcon(count) {
    if (clusterIconCache[count]) return clusterIconCache[count];
    var canvas = document.createElement('canvas');
    canvas.width = CLUSTER_SIZE;
    canvas.height = CLUSTER_SIZE;
    var ctx = canvas.getContext('2d');

    ctx.beginPath();
    ctx.arc(CENTER_OFFSET, CENTER_OFFSET, SHADOW_RADIUS, 0, 2 * Math.PI);
    ctx.fillStyle = 'rgba(0, 0, 0, 0.15)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(CENTER_OFFSET, CENTER_OFFSET, BALL_RADIUS, 0, 2 * Math.PI);
    ctx.fillStyle = '#000000';
    ctx.fill();

    ctx.fillStyle = 'white';
    ctx.font = 'bold 1.2rem Lato, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(String(count), CENTER_OFFSET, CENTER_OFFSET);

    var dataUrl = canvas.toDataURL();
    clusterIconCache[count] = dataUrl;
    return dataUrl;
  }

  // Returns null if the URL is empty or the image fails toload
  function loadMarkerImage(url) {
    return new Promise(function (resolve) {
      if (!url) {
        resolve(null);
        return;
      }
      var img = new Image();
      img.onload = function () { resolve(img); };
      img.onerror = function () { resolve(null); };
      img.src = url;
    });
  }

  // custom marker element from each image.
  function buildMarkerEl(img, size) {
    var el = document.createElement('div');
    el.style.cursor = 'pointer';
    if (img) {
      var w = size && size[0] ? size[0] : img.naturalWidth || 21;
      var h = size && size[1] ? size[1] : img.naturalHeight || 26;
      img.style.width = w + 'px';
      img.style.height = h + 'px';
      el.appendChild(img);
    }
    return el;
  }

  function toLngLat(lat, lng) {
    return new maplibregl.LngLat(lng, lat);
  }

  function init(containerId, options) {
    if (typeof maplibregl === 'undefined') {
      console.warn('ICU.Maps: maplibregl is not loaded');
      return null;
    }
    var el = typeof containerId === 'string' ? document.getElementById(containerId) : containerId;
    if (!el) {
      console.warn('ICU.Maps: container not found', containerId);
      return null;
    }
    options = options || {};
    var markers = options.markers || [];
    var cluster = !!options.cluster && markers.length > 0;
    var autoFit = options.fit !== false && markers.length > 0;

    var center = options.center
      ? [options.center[1], options.center[0]] // [lat,lng] -> [lng,lat]
      : DEFAULT_CENTER;
    var zoom = options.zoom != null ? options.zoom : DEFAULT_ZOOM;

    var enableZoom = options.zoomControl !== false;
    var enableFullscreen = options.fullscreenControl !== false;

    var map = new maplibregl.Map({
      container: el,
      style: DEFAULT_STYLE,
      center: center,
      zoom: zoom,
      attributionControl: false
    });
    map.addControl(new maplibregl.AttributionControl({ compact: true }));

    if (enableZoom) {
      map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
    }
    if (enableFullscreen) {
      map.addControl(new maplibregl.FullscreenControl(), 'top-right');
    }

    function bindPopupRecenter(marker) {
      var popup = marker.getPopup();
      if (!popup) return;
      popup.on('close', function () {
        map.easeTo({ center: center, zoom: zoom });
      });
    }

    var addMarkersDirectly = function (list) {
      var imagePromises = list.map(function (m) {
        return loadMarkerImage(m.iconUrl).then(function (img) {
          return { marker: m, img: img };
        });
      });
      Promise.all(imagePromises).then(function (items) {
        items.forEach(function (item) {
          var m = item.marker;
          var el = buildMarkerEl(item.img, MARKER_SIZE);
          var marker = new maplibregl.Marker({ element: el })
            .setLngLat([m.lng != null ? m.lng : m[1], m.lat != null ? m.lat : m[0]]);
          if (m.title) el.title = m.title;
          if (m.popupHtml) {
            var popup = new maplibregl.Popup({ closeButton: true, closeOnClick: true })
              .setHTML(m.popupHtml);
            marker.setPopup(popup);
            bindPopupRecenter(marker);
          }
          marker.addTo(map);
        });
      });
    };

    var addMarkersAsCluster = function (list) {
      var features = list.map(function (m, i) {
        return {
          type: 'Feature',
          id: i,
          properties: { title: m.title || '', iconUrl: m.iconUrl || '', popupHtml: m.popupHtml || '' },
          geometry: { type: 'Point', coordinates: [m.lng != null ? m.lng : m[1], m.lat != null ? m.lat : m[0]] }
        };
      });

      // Pre-load every unique marker icon once so renderUnclustered can build
      // DOM markers synchronously and avoid orphan markers during zoom transitions.
      var iconCache = {};
      var uniqueIconUrls = [];
      var seenUrls = {};
      list.forEach(function (m) {
        if (m.iconUrl && !seenUrls[m.iconUrl]) {
          seenUrls[m.iconUrl] = true;
          uniqueIconUrls.push(m.iconUrl);
        }
      });
      var preloadIcons = Promise.all(uniqueIconUrls.map(function (url) {
        return loadMarkerImage(url).then(function (img) {
          iconCache[url] = img;
        });
      }));

      var loadingIcons = {};

      var onReady = function () {
        map.addSource('icu-markers', {
          type: 'geojson',
          data: { type: 'FeatureCollection', features: features },
          cluster: true,
          clusterRadius: CLUSTER_RADIUS,
          clusterMaxZoom: CLUSTER_MAX_ZOOM,
          clusterMinPoints: CLUSTER_MIN_POINTS
        });

        // Invisible hitbox for cluster clicks.
        map.addLayer({
          id: 'icu-clusters',
          type: 'circle',
          source: 'icu-markers',
          filter: ['has', 'point_count'],
          paint: { 'circle-radius': 20, 'circle-opacity': 0 }
        });

        // Cluster count circles.
        map.addLayer({
          id: 'icu-cluster-icons',
          source: 'icu-markers',
          filter: ['has', 'point_count'],
          type: 'symbol',
          layout: {
            'icon-image': 'icu-cluster-{point_count}',
            'icon-size': 1,
            'icon-allow-overlap': true,
            'icon-ignore-placement': true
          },
          paint: {}
        })

        var unclusteredMarkers = {};
        var renderUnclustered = function () {
          var featuresInView = map.querySourceFeatures('icu-markers', {
            filter: ['!', ['has', 'point_count']]
          }).filter(function (f) {
            return !f.properties.cluster && f.properties.point_count == null;
          });
          var seen = {};
          featuresInView.forEach(function (f) {
            var coords = f.geometry.coordinates;
            var key = f.id != null ? String(f.id) : coords[0].toFixed(6) + ',' + coords[1].toFixed(6);
            seen[key] = true;
            if (unclusteredMarkers[key]) return;
            var props = f.properties || {};
            var popupHtml = props.popupHtml || '';
            var img = iconCache[props.iconUrl] || null;
            var el = buildMarkerEl(img ? img.cloneNode() : null, MARKER_SIZE);
            if (props.title) el.title = props.title;
            var marker = new maplibregl.Marker({ element: el }).setLngLat(coords);
            if (popupHtml) {
              marker.setPopup(
                new maplibregl.Popup({ closeButton: true, closeOnClick: true }).setHTML(popupHtml)
              );
              bindPopupRecenter(marker);
            }
            marker.addTo(map);
            unclusteredMarkers[key] = { marker: marker, coords: coords, popupHtml: popupHtml };
          });
          for (var k in unclusteredMarkers) {
            if (!seen[k]) {
              unclusteredMarkers[k].marker.remove();
              delete unclusteredMarkers[k];
            }
          }
        };

        map.on('idle', renderUnclustered);
        map.on('moveend', renderUnclustered);

        // lazy registers cluster markers per point_count on screen.
        map.on('render', function () {
          var clusters = map.querySourceFeatures('icu-markers', {
            filter: ['has', 'point_count']
          });
          clusters.forEach(function (c) {
            var count = c.properties.point_count;
            var iconName = 'icu-cluster-' + count;
            if (!map.hasImage(iconName) && !loadingIcons[iconName]) {
              loadingIcons[iconName] = true;
              var img = new Image();
              img.onload = function () {
                if (!map.hasImage(iconName)) {
                  map.addImage(iconName, img);
                }
                delete loadingIcons[iconName];
              };
              img.onerror = function () {
                delete loadingIcons[iconName];
              };
              img.src = buildClusterIcon(count);
            }
          });
        });

        renderUnclustered();

        map.on('click', 'icu-cluster-icons', function (e) {
          var feature = e.features[0];
          var clusterId = feature.properties.cluster_id;
          map.getSource('icu-markers').getClusterExpansionZoom(clusterId).then(function (expansionZoom) {
            map.easeTo({
              center: feature.geometry.coordinates,
              zoom: expansionZoom + 2
            });
          }).catch(function (err) {
            console.warn('ICU.Maps: cluster expansion failed', err);
          });
        });

        map.on('mouseenter', 'icu-cluster-icons', function () {
          map.getCanvas().style.cursor = 'pointer';
        });
        map.on('mouseleave', 'icu-cluster-icons', function () {
          map.getCanvas().style.cursor = '';
        });
      };

      Promise.all([
        new Promise(function (resolve) { map.on('load', resolve); }),
        preloadIcons
      ]).then(onReady);
    };

    // if fit => false isn't present
    var fitToMarkers = function () {
      if (!markers.length) return;
      var lngs = markers.map(function (m) { return m.lng != null ? m.lng : m[1]; });
      var lats = markers.map(function (m) { return m.lat != null ? m.lat : m[0]; });
      var bounds = [
        [Math.min.apply(null, lngs), Math.min.apply(null, lats)],
        [Math.max.apply(null, lngs), Math.max.apply(null, lats)]
      ];
      // Small padding so the outer markers aren't flush against the edge.
      map.fitBounds(bounds, { padding: 40, maxZoom: 13 });
    };

    if (cluster) {
      addMarkersAsCluster(markers);
    } else {
      map.on('load', function () {
        addMarkersDirectly(markers);
      });
    }

    if (autoFit) {
      map.on('load', fitToMarkers);
    }

    return map;
  }

  // reads JSON from the script tag
  function readData(scriptId) {
    var el = document.getElementById(scriptId);
    if (!el) return {};
    try {
      return JSON.parse(el.textContent);
    } catch (e) {
      console.warn('ICU.Maps: failed to parse data for #' + scriptId, e);
      return {};
    }
  }

  return {
    init: init,
    readData: readData
  };
})();
