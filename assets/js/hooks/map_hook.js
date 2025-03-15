const MapHook = {
  mounted() {
    // Parse data from the component
    const headquarters = JSON.parse(this.el.dataset.headquarters);
    const orders = JSON.parse(this.el.dataset.orders);
    console.log(orders)
    // Initialize the map
    const map = new maplibregl.Map({
      container: this.el.querySelector('div').id,
      style: 'https://api.maptiler.com/maps/dataviz/style.json?key=YRoWGCY9Di8M1FP1yWxs',
      center: [5.7245, 45.1885], // Default center (Grenoble)
      zoom: 12
    });

    // Wait for the map style to be fully loaded before adding markers and routes
    map.on('style.load', () => {
      const hqMarkers = new Map(); // Pour stocker les marqueurs des QG
      const orderMarkers = new Map(); // Pour stocker les marqueurs des commandes
      const orderLines = new Map(); // Pour stocker les lignes des commandes

      // Add markers for headquarters
      headquarters.forEach(hq => {
        // Create a custom DOM element for the marker
        const el = document.createElement('div');
        el.className = 'marker';
        el.style.width = '32px';
        el.style.height = '32px';
        el.style.backgroundImage = 'url(https://cdn-icons-png.flaticon.com/512/619/619153.png)';
        el.style.backgroundSize = '100%';
        el.style.filter = `hue-rotate(${hq.color ? hq.color : '0deg'})`;

        const marker = new maplibregl.Marker({
          element: el
        })
          .setLngLat([hq.longitude, hq.latitude])
          .setPopup(new maplibregl.Popup().setHTML(`
            <h3 class="font-bold">${hq.name}</h3>
            <p>${hq.address}</p>
          `))
          .addTo(map);

        // Stocker le marqueur du QG
        hqMarkers.set(hq.id, marker);

        // Ajouter les événements de survol sur le marqueur du QG
        const markerElement = marker.getElement();
        markerElement.addEventListener('mouseenter', () => {
          // Afficher toutes les lignes des commandes de ce QG
          orders.forEach(order => {
            if (order.headquarters_id === hq.id) {
              map.setLayoutProperty(`route-${order.id}`, 'visibility', 'visible');
              orderMarkers.get(order.id).getElement().style.opacity = '1';
            }
          });
        });

        markerElement.addEventListener('mouseleave', () => {
          // Cacher toutes les lignes
          orders.forEach(order => {
            if (order.headquarters_id === hq.id) {
              map.setLayoutProperty(`route-${order.id}`, 'visibility', 'none');
              orderMarkers.get(order.id).getElement().style.opacity = '0.5';
            }
          });
        });
      });

      // Add markers and lines for orders
      orders.forEach(order => {
        const hq = headquarters.find(h => h.id === order.headquarters_id);
        if (!hq) return;
        console.log(order.latitude_livraison, order.longitude_livraison)
        // Add marker for delivery location
        const orderMarker = new maplibregl.Marker({
          color: hq.color || '#0000FF'
        })
          .setLngLat([order.longitude_livraison, order.latitude_livraison])
          .setPopup(new maplibregl.Popup().setHTML(`
            <h3 class="font-bold">Commande #${order.id}</h3>
            <p>Status: ${order.status}</p>
            <p>Livré par: ${hq.name}</p>
          `))
          .addTo(map);

        // Stocker le marqueur de la commande
        orderMarkers.set(order.id, orderMarker);

        // Ajouter les événements de survol sur le marqueur de la commande
        const markerElement = orderMarker.getElement();
        markerElement.style.opacity = '0.5'; // Opacité réduite par défaut
        markerElement.addEventListener('mouseenter', () => {
          markerElement.style.opacity = '1';
          map.setLayoutProperty(`route-${order.id}`, 'visibility', 'visible');
        });
        markerElement.addEventListener('mouseleave', () => {
          markerElement.style.opacity = '0.5';
          map.setLayoutProperty(`route-${order.id}`, 'visibility', 'none');
        });

        // Draw line between HQ and delivery location (hidden by default)
        map.addSource(`route-${order.id}`, {
          type: 'geojson',
          data: {
            type: 'Feature',
            properties: {},
            geometry: {
              type: 'LineString',
              coordinates: [
                [hq.longitude, hq.latitude],
                [order.longitude_livraison, order.latitude_livraison]
              ]
            }
          }
        });

        map.addLayer({
          id: `route-${order.id}`,
          type: 'line',
          source: `route-${order.id}`,
          layout: {
            'line-join': 'round',
            'line-cap': 'round',
            'visibility': 'none' // Caché par défaut
          },
          paint: {
            'line-color': hq.color || '#0000FF',
            'line-width': 2,
            'line-opacity': 0.7
          }
        });

        // Stocker la ligne
        orderLines.set(order.id, `route-${order.id}`);
      });

      // Fit bounds to include all markers
      const bounds = new maplibregl.LngLatBounds();
      headquarters.forEach(hq => {
        bounds.extend([hq.longitude, hq.latitude]);
      });
      orders.forEach(order => {
        bounds.extend([order.longitude_livraison, order.latitude_livraison]);
      });
      map.fitBounds(bounds, { padding: 50 });
    });
  }
}

export default MapHook; 