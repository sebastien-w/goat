--THIS FUNCTION CHECKS THE SELECTED ROUTING PROFILE AND IF THE USER INSERTED OPENING HOURS AND EXECUTS THE CORRESPONDING FUNCTION TO CREATE THE GEOSERVER VIEW
DROP FUNCTION IF EXISTS pois_visualization;
CREATE OR REPLACE FUNCTION public.pois_visualization(amenities_input text, routing_profile_input text, d integer, h integer, m integer)
 RETURNS SETOF pois_visualization
 LANGUAGE plpgsql
AS $function$
DECLARE 	
	wheelchair_condition text[];
begin

DROP TABLE IF EXISTS visualization_pois;


    --if no opening hours are provided by the user and routing profile is -not- wheelchair
    IF (d = 9999 OR h = 9999 OR m = 9999) AND routing_profile_input <> 'walking_wheelchair' THEN 
        RETURN query
        SELECT p.name,p.osm_id,p.opening_hours,p.orgin_geometry,p.geom, NULL AS status,p.wheelchair
        FROM pois p,variable_container v 
        WHERE p.amenity IN(amenities_input)
        AND v.identifier = 'poi_categories'
        UNION ALL 
        SELECT pt.name,NULL AS osm_id,NULL AS orgin_geometry,NULL AS opening_hours,pt.geom , NULL AS status,pt.wheelchair
        FROM public_transport_stops pt 
        WHERE public_transport_stop IN(amenities_input);
    --if no opening hours are provided by the user and routing profile is wheelchair
    ELSEIF (d = 9999 OR h = 9999 OR m = 9999) AND routing_profile_input = 'walking_wheelchair' THEN 
        RETURN query
        SELECT p.name,p.osm_id,p.opening_hours,p.orgin_geometry,p.geom, NULL AS status,p.wheelchair
        FROM pois p,variable_container v 
        WHERE p.amenity IN(amenities_input)
        AND ((p.wheelchair <> 'no' AND p.wheelchair <> 'No') OR p.wheelchair IS NULL)
        AND v.identifier = 'poi_categories'
        UNION ALL 
        SELECT pt.name,NULL AS osm_id,NULL AS orgin_geometry,NULL AS opening_hours,pt.geom , NULL AS status,pt.wheelchair
        FROM public_transport_stops pt 
        WHERE public_transport_stop IN(amenities_input)
        AND ((wheelchair <> 'no' AND wheelchair <> 'No') OR wheelchair IS NULL);
    --if opening hours are provided by the user and routing profile is -not- wheelchair
    ELSEIF d <> 9999 AND h <> 9999 AND m <> 9999 AND routing_profile_input <> 'walking_wheelchair' THEN 
        RETURN query
        WITH pois_status AS 
        (
            SELECT p.name,p.osm_id,p.opening_hours,p.orgin_geometry,p.geom,check_open(p.opening_hours,array[d,h,m]) AS status,p.wheelchair
            FROM pois p
            WHERE p.amenity IN(amenities_input)
            AND opening_hours IS NOT NULL
        )
        SELECT * FROM pois_status
        WHERE status = 'True'
        UNION ALL
        SELECT pt.name,NULL AS osm_id, NULL AS opening_hours, NULL AS orgin_geometry,pt.geom, NULL AS status, wheelchair 
        FROM public_transport_stops pt 
        WHERE public_transport_stop IN(amenities_input);
    --if opening hours are provided by the user and routing profile is wheelchair
    ELSE 
        RETURN query
        WITH pois_status AS 
        (
            SELECT p.name,p.osm_id,p.opening_hours,p.orgin_geometry,p.geom,check_open(p.opening_hours,array[d,h,m]) AS status, p.wheelchair 
            FROM pois p
            WHERE p.amenity IN(amenities_input)
            AND opening_hours IS NOT NULL
        )
        SELECT * FROM pois_status
        WHERE status = 'True'
        AND ((wheelchair <> 'no' AND wheelchair <> 'No') OR wheelchair IS NULL)
        UNION ALL
        SELECT pt.name,NULL AS osm_id, NULL AS opening_hours, NULL AS orgin_geometry,pt.geom, NULL AS status, wheelchair 
        FROM public_transport_stops pt 
        WHERE public_transport_stop IN(amenities_input)
        AND ((wheelchair <> 'no' AND wheelchair <> 'No') OR wheelchair IS NULL);
    END IF;

END ;
$function$

/* SELECT * FROM 
	(SELECT * FROM regexp_split_to_table(convert_from(decode('cmVzdGF1cmFudCxzdXBlcm1hcmtldA==','base64'),'UTF-8'), ',') AS amenity) x,
	pois_visualization(x.amenity,'walking_wheelchair', 20, 15, 0);
*/
