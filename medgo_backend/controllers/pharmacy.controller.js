const { supabase } = require('../config/supabase');
const { nearbyPharmaciesSchema, validate } = require('../utils/validators');
const { sendSuccess, sendError } = require('../utils/response');

/**
 * Calculate Haversine distance between two coordinates in kilometers
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10; // Rounded to 1 decimal place
}

/**
 * Determine if pharmacy is currently open considering business hours and midnight crossing
 */
function isCurrentlyOpen(isOpenFlag, openingTime, closingTime) {
  if (!isOpenFlag) return false;
  if (!openingTime || !closingTime) return isOpenFlag;

  const now = new Date();
  const currentHours = String(now.getHours()).padStart(2, '0');
  const currentMinutes = String(now.getMinutes()).padStart(2, '0');
  const currentTime = `${currentHours}:${currentMinutes}`;

  const open = openingTime.slice(0, 5);
  const close = closingTime.slice(0, 5);

  if (open <= close) {
    return currentTime >= open && currentTime <= close;
  } else {
    // Crosses midnight (e.g., 20:00 to 04:00)
    return currentTime >= open || currentTime <= close;
  }
}

/**
 * Format time string HH:mm:ss -> HH:mm
 */
function formatTime(timeStr) {
  if (!timeStr) return '';
  return timeStr.slice(0, 5);
}

class PharmacyController {
  /**
   * GET /api/v1/pharmacies
   * Query params: lat, lng, radius_km
   */
  async getNearbyPharmacies(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const { lat, lng, radius_km } = req.query;

      // Fetch pharmacies with owner name from users
      const { data: pharmacies, error } = await supabase
        .from('pharmacies')
        .select(`
          id,
          name,
          address,
          latitude,
          longitude,
          opening_time,
          closing_time,
          is_open,
          phone,
          users!owner_id (
            name
          )
        `);

      if (error) {
        throw error;
      }

      let parsedLat = null;
      let parsedLng = null;
      let maxRadius = null;

      if (lat !== undefined && lng !== undefined) {
        const val = validate(nearbyPharmaciesSchema, { lat, lng, radius_km });
        if (!val.success) {
          return sendError(res, val.error, 400);
        }
        parsedLat = val.data.lat;
        parsedLng = val.data.lng;
        maxRadius = val.data.radius_km || 10; // default 10km radius if not specified
      }

      const formatted = pharmacies
        .map((p) => {
          let distance = null;
          if (parsedLat !== null && parsedLng !== null) {
            distance = calculateDistance(parsedLat, parsedLng, p.latitude, p.longitude);
          }

          const openStatus = isCurrentlyOpen(p.is_open, p.opening_time, p.closing_time);

          return {
            id: p.id,
            name: p.name,
            owner_name: p.users ? p.users.name : 'Unknown',
            address: p.address,
            latitude: p.latitude,
            longitude: p.longitude,
            distance_km: distance !== null ? distance : 0,
            is_open: openStatus,
            opening_time: formatTime(p.opening_time),
            closing_time: formatTime(p.closing_time),
            phone: p.phone,
          };
        })
        .filter((p) => {
          if (maxRadius !== null) {
            return p.distance_km <= maxRadius;
          }
          return true;
        })
        .sort((a, b) => a.distance_km - b.distance_km);

      return sendSuccess(res, formatted, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /api/v1/pharmacies/:id
   */
  async getPharmacyById(req, res, next) {
    try {
      if (!supabase) {
        return sendError(res, 'Database client is not initialized', 500);
      }

      const { id } = req.params;

      const { data: pharmacy, error } = await supabase
        .from('pharmacies')
        .select(`
          id,
          name,
          address,
          latitude,
          longitude,
          opening_time,
          closing_time,
          is_open,
          phone,
          users!owner_id (
            name
          )
        `)
        .eq('id', id)
        .maybeSingle();

      if (error) {
        throw error;
      }

      if (!pharmacy) {
        return sendError(res, 'Pharmacy not found', 404);
      }

      const openStatus = isCurrentlyOpen(pharmacy.is_open, pharmacy.opening_time, pharmacy.closing_time);

      const result = {
        id: pharmacy.id,
        name: pharmacy.name,
        owner_name: pharmacy.users ? pharmacy.users.name : 'Unknown',
        address: pharmacy.address,
        latitude: pharmacy.latitude,
        longitude: pharmacy.longitude,
        phone: pharmacy.phone,
        opening_time: formatTime(pharmacy.opening_time),
        closing_time: formatTime(pharmacy.closing_time),
        is_open: openStatus,
      };

      return sendSuccess(res, result, 200);
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new PharmacyController();
