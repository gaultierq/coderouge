// will init the map from the last 5 positions
function initMap(lastPositions) {

  var map = new google.maps.Map(document.getElementById('map'));

var bounds = new google.maps.LatLngBounds();
var infowindow = new google.maps.InfoWindow();

var latLngs = []

for (var i = 0; i < lastPositions.length; i++) {
  var pos = lastPositions[i]
  var latLng = new google.maps.LatLng(pos.latitude, pos.longitude);
latLngs.push(latLng)

var marker = new google.maps.Marker({
  position: latLng,
  map: map
});

//extend the bounds to include each marker's position
bounds.extend(marker.position);

//??
  google.maps.event.addListener(marker, 'click', (function(marker, i) {
    return function() {
      infowindow.setContent(locations[i][0]);
    infowindow.open(map, marker);
}
})(marker, i));
}

//now fit the map to the newly inclusive bounds
map.fitBounds(bounds);

var line= new google.maps.Polyline({
  path: latLngs,
  geodesic: true,
  strokeColor: '#FF0000',
  strokeOpacity: 1.0,
  strokeWeight: 1
});

line.setMap(map);

}