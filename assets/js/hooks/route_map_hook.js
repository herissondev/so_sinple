// Use global polyline library included via CDN instead of importing it
const RouteMapHook = {
  mounted() {
    // Parse data from the component
    const fromCoords = JSON.parse(this.el.dataset.fromCoords); // [lat, lng]
    const toCoords = JSON.parse(this.el.dataset.toCoords); // [lat, lng]
    const encodedRoute = this.el.dataset.encodedRoute;

    // Initialize the map
    const map = new maplibregl.Map({
      container: this.el.querySelector('div').id,
      style: 'https://api.maptiler.com/maps/dataviz/style.json?key=YRoWGCY9Di8M1FP1yWxs',
      center: [fromCoords[1], fromCoords[0]], // Default center (from coordinates)
      zoom: 14
    });

    // Wait for the map style to be fully loaded before adding the route
    map.on('style.load', () => {
      // Decode the polyline into an array of [lat, lng] points
      const decodedPoints = polyline.decode(encodedRoute);
      
      // Convert to [lng, lat] format for MapLibre
      const coordinates = decodedPoints.map(([lat, lng]) => [lng, lat]);

      // Add markers for the start and end points
      // Start marker (green)
      const startEl = document.createElement('div');
      startEl.className = 'marker start-marker';
      startEl.style.width = '24px';
      startEl.style.height = '24px';
      startEl.style.backgroundImage = 'url(https://cdn-icons-png.flaticon.com/512/2775/2775994.png)';
      startEl.style.backgroundSize = '100%';

      new maplibregl.Marker({
        element: startEl
      })
        .setLngLat([fromCoords[1], fromCoords[0]])
        .setPopup(new maplibregl.Popup().setHTML('<h3 class="font-bold">Départ</h3>'))
        .addTo(map);

      // End marker (red)
      const endEl = document.createElement('div');
      endEl.className = 'marker end-marker';
      endEl.style.width = '24px';
      endEl.style.height = '24px';
      endEl.style.backgroundImage = 'url(https://cdn-icons-png.flaticon.com/512/1055/1055470.png)';
      endEl.style.backgroundSize = '100%';

      new maplibregl.Marker({
        element: endEl
      })
        .setLngLat([toCoords[1], toCoords[0]])
        .setPopup(new maplibregl.Popup().setHTML('<h3 class="font-bold">Arrivée</h3>'))
        .addTo(map);

      // Add the route as a GeoJSON source
      map.addSource('route', {
        type: 'geojson',
        data: {
          type: 'Feature',
          properties: {},
          geometry: {
            type: 'LineString',
            coordinates: coordinates
          }
        }
      });

      // Add a layer to display the route line
      map.addLayer({
        id: 'route-line',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#0074D9',
          'line-width': 4,
          'line-opacity': 0.8
        }
      });

      // Fit the map to the route
      const bounds = coordinates.reduce(
        (bounds, coord) => bounds.extend(coord),
        new maplibregl.LngLatBounds(coordinates[0], coordinates[0])
      );
      
      map.fitBounds(bounds, {
        padding: 40
      });
    });
  }
};

export default RouteMapHook; 