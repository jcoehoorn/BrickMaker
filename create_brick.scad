//Number of studs long
length = 4;

//Number of studs wide
width = 1;

//Nozzle Size
// Used to avoid generating support lines too skinny to print well. If you want exact lines, lie and set this to something small like .1mm.
nozzle_size = 0.4;

// This adjustment will be removed from the thickness of the wall on *both sides* and does impact the overall size of the resulting brick.
wall_adjustment = 0.1;

// Use this and the support post adjustment to compensate for material removed from the walls
ridge_depth_adjustment = -0.1;

//Additional spacing factor between individual pieces. This adjustment will reduce the length of walls on *both sides*, but not the thickness of the wall.
gap_factor = -0.1; 

//Amount to remove from brick height. Divided by three for plates/bases. Typically full-height bricks are already okay, but plates may need a height reduction.
height_adjustment = 0;

//Amount to remove from the height of studs
stud_height_adjustment = 0.1;

//Amount to remove from the radius of studs
stud_radius_adjustment = -0.06;

//Amount to remove from the radius of the supports posts. Only used on 2xN pieces. Default is one quarter of the standard play factor
support_post_radius_adjustment = 0.022;

//Full-height brick vs plate vs base. A base is a plate with a completely flat bottom. Base is NOT SUPPORTED yet. You will end up with a plate.
block_type = "plate"; // [brick:Brick, plate:Plate, base:Base]

//Normal has studs, tiles do not
surface_type = "normal"; // [normal:Normal, tile:Tile]


/* No need to modify anything else */

/* [Hidden] */

lego_unit = 1.6; // standard lego unit
LU = lego_unit; //short-hand

play_factor = 0.1; // standard lego play factor
PF = play_factor; //short-hand

unit_span = 5*LU;
SU = unit_span; //short-hand (stands for: Stud Unit)

module LEGO_BLOCK(le, wi, he, t)
{
    difference() {
        cube([le, wi, he], 0);
        translate([t, t, -0.1])
        {
            cube([le - t*2, wi-t*2, (he-t)+0.1], 0);
        }
    }
}

module LEGO_STUDS(studs_x, studs_y, xy_offset_to_first_stud, z_offset, radius_adjustment, height_adjustment)
{
    /* STUD HEIGHT:
     There is confusion over this. Different sources I looked at claim
     different things about the height of a stud.
     Some people say 1.8, some say 1.7, and some say 1.6 (one lego unit).
     
     I believe actual lego studs are 1.8, *but this includes the "lego" emboss.*
     Put another way, studs are:
      * One standart Lego Unit (1.6 mm)
      * Plus one standard Play Factor (0.1 mm)
      * Plus the emboss height (0.1 mm)
     Therefore the actual total is 1.8 mm. This interpretation makes sense, 
     because it explains why we have this confusion.  
     
     When we apply this to 3D printing, though, 
      a more practical default printing height ignores the emboss.
     Therefore, I'll use 1.7 mm.
    */
    
    base_stud_height = LU + PF;
    stud_height = base_stud_height - height_adjustment;

    stud_rad = (1.5*LU) - radius_adjustment;   
    xy_init = xy_offset_to_first_stud;
    
    for(y=[0:studs_y-1])
    {
        for(x=[0:studs_x-1])
        {
            translate([xy_init+(x*SU),xy_init+(y*SU),z_offset])
            {
                cylinder(stud_height,stud_rad, stud_rad, $fn=40);
            };
        }
    }
}

module LEGO_RIDGES(studs_x, studs_y, ridge_width, ridge_depth, ridge_height, wall_thickness_offset, xy_offset_to_first_stud, offset_to_far_x_wall, offset_to_far_y_wall)
{
    xy_init = xy_offset_to_first_stud;
    WO = wall_thickness_offset;
    
    x_offset=offset_to_far_x_wall;
    y_offset=offset_to_far_y_wall;
    
    //long edge
    for(x=[0:studs_x-1])
    {  
        translate([xy_init+(x*SU)-(ridge_width/2), WO, 0])
        {
            cube([ridge_width, ridge_depth, ridge_height],0);
        }
        translate([xy_init+(x*SU)-(ridge_width/2), y_offset - ridge_depth, 0]) 
        {
            cube([ridge_width, ridge_depth, ridge_height],0);
        }
    }

    //short edge
    for(y=[0:studs_y-1])
    {  
        //near side
        translate([WO,xy_init+(y*SU)-(ridge_width/2), 0])
        {
            cube([ridge_depth, ridge_width, ridge_height],0);
        }
        //far side
        translate([x_offset - ridge_depth, xy_init + (y * SU)-(ridge_width / 2),0]) 
        {
            cube([ridge_depth, ridge_width, ridge_height],0);
        }
    }
}


module LEGO_POSTS(studs_x, studs_y, post_height, wall_thickness_offset, xy_offset_to_first_stud, minimum_thickness, support_post_radius_adjustment)
{
    
    xy_init = xy_offset_to_first_stud;
    WO = wall_thickness_offset;
    min_t = minimum_thickness;
    
    
    include_cross_supports = "Y"; // [Y:Yes, N:No]
/* Note for above: moved to hidden section, because if you can't bridge that you're gonna have problems anyway when it's time to print the top wall */
    
   if (studs_y==1 && studs_x > 1)
   {
        //Nx1 posts (narrow solid, cross support on every post)
        
        /*Note on adjument factor for the post radius.
        
           Since these posts are 1LU, and studs are 3LU, 
           it's tempting to just use 1/3 that.
           However, I believe it's about area, rather than radius here.
           Thus, 1/9 is more appropriate (square of the sides).
           (LU-(stud_radius_adjustment/9)) 
          
           Of course, I could also be way off :)
           For now, I'm not doing either. Tests so far
           using un-adjusted posts, and 1xN bricks fit
           better than almost anything else I print. 
           I may put an adjustment back in the future if people ask for it.   
        */
        
        support_w = LU/4<min_t?min_t:LU/4;
        
        for(x=[1:studs_x-1])
        {  
            translate([xy_init + (SU*x)-(SU/2),xy_init,0])
            {   //only 1 wide, so skinny middle post
                cylinder(post_height, LU, LU, $fn=32);
            }
            
            //cross supports
            if (include_cross_supports == "Y")
            {
                translate([xy_init + (x*SU) -(SU/2) - (support_w/2), 0, LU])
                { 
                    cube([support_w,SU - 2*(LU-WO), post_height- LU],0);
                }        
            }
        }
    }
    else  if (studs_y > 1)
    {
        // Nx2+ posts (wide hollow, cross support every other post)
        
        // Not sure how to handle cross support yet for non-standard (odd-length)
        // bricks with an even number of posts. 
        // Supports are there, but not aligned well.
        
        sup_w = LU/2<(2*min_t)?(2*min_t):LU/2;
        outer = ((((pow(2,0.5)*5)-3)/2) * LU)-support_post_radius_adjustment;
        inner = outer - sup_w;    
        sup_l = (SU-outer-WO)/2;
        
        x_adjust = xy_init - (SU/2) - (sup_w/2);
        
        for(x=[1:studs_x-1])
        {
            for(y=[1:studs_y-1])
            {  
                difference()
                {
                    translate([SU*x + xy_init - (SU/2),SU*y + xy_init - (SU/2), 0])
                    {
                        cylinder(post_height-0.1, outer, outer, $fn=40);
                    }
                    //bottom dimensions needs to *overlap* outer post, not match exactly
                    translate([SU*x + xy_init - (SU/2),SU*y + xy_init - (SU/2), -0.1])
                    {
                        cylinder((post_height-LU)+0.1, inner, inner, $fn=40);
                    }
                }
                
                //partial cross supports (between two posts)
                if (include_cross_supports == "Y" && x%2==0 && y > 1)
                {       
                    translate([x_adjust + (SU*x), (SU*y)+xy_init - (SU/2)- outer - (SU-(2*outer)), LU])
                    { 
                        cube([sup_w,SU-(2*outer),post_height - LU - WO],0);
                    }               
                }            
            }
            
            //remaining cross supports (outer walls to nearest post)
            if (include_cross_supports == "Y")        
            { 
                sup_l = SU-WO-outer+0.2; //cheat a bit, because we're not matching to a flat surface
               
                if (x%2 == 0)
                {   
                    //near wall
                    translate([x_adjust+ (SU*x),WO,LU])
                    { 
                        cube([sup_w,sup_l,post_height-LU-WO],0);
                    }
                    //far wall
                    translate([x_adjust+ (SU*x),(SU*studs_y) - WO - sup_l,LU])
                    { 
                        cube([sup_w,sup_l,post_height-LU-WO],0);
                    }
                }
            }
        }
    } 
}


//TODO: way to make the top wall skinnier for larger nozzle sizes
//TODO: ridge adjustments (needed because of wall and nozzle adjustments)


module LEGO_FULL(studs_long, studs_wide, brick_type, surface_type, wall_adjustment, gap_factor, stud_height_adjustment, stud_radius_adjustment, support_post_radius_adjustment, ridge_depth_adjustment, use_ridges_with_plates)
{
    //brick is default. If we don't understand this, default to brick height
    brick_height = ((block_type == "plate" || block_type == "base")? (2*LU) : 6*LU);

    final_height_adjustment = height_adjustment / ((block_type == "plate" || block_type == "base")? 3 : 1);
        
        wall_thickness = LU - (2 * (PF + wall_adjustment));

    w = (width > length)?length:width;
    l = (width > length)?width:length; //TODO: l vs 1 can be hard to see
    h = brick_height - final_height_adjustment;

    G = gap_factor; //short-hand
    WT = wall_thickness; //short-hand
    WA = PF + wall_adjustment; //short-hand; stands for Play Factor (Lego's term, I believe)

    long_wall_l = (l*SU)-(2*G)-(2*WA);
    short_wall_l = (w*SU)-(2*G)-(2*WA);   

    //Supports across the underside of the brick.
    // Do not appear on plates.
    // They bridge up to a 3.2mm gap about 1.6mm above the build surface, so set this to "No" if the gap will cause a problem for your printer
    
    include_cross_supports = "Y"; // [Y:Yes, N:No]
    /* Note for above: moved to hidden section, because if you can't bridge that you're gonna have problems anyway when it's time to print the top wall */
    
    //brick is default. If we don't understand this, default to brick height
    brick_height = ((brick_type == "plate" || brick_type == "base")? (2*LU) : 6*LU);
    
    final_height_adjustment = height_adjustment / ((block_type == "plate" || block_type == "base")? 3 : 1);

    w = (width > length)?length:width;
    l = (width > length)?width:length; //TODO: l vs 1 can be hard to see
    h = brick_height - final_height_adjustment;

    G = gap_factor; //short-hand
    WT = wall_thickness; //short-hand
    WA = PF + wall_adjustment; //short-hand; stands for Play Factor (Lego's term, I believe)

    //BRICK
   
    long_wall_l = (l*SU)-(2*G)-(2*WA);
    short_wall_l = (w*SU)-(2*G)-(2*WA);

    first_stud = (SU/2) - WA - G;

    LEGO_BLOCK(long_wall_l, short_wall_l, h, WT);    

    //STUDS   
    
    if (surface_type != "tile") 
    { 
        //default as "normal". If we don't understand the value, default to true
        LEGO_STUDS(l, w, first_stud, h, stud_radius_adjustment, stud_height_adjustment);
    }
    
    //INTERIOR RIDGES

    // plates and bases do not have ridges
    //TODO: test prints of plates are too loose compared to bricks. 
    // Real lego does not use ridges for plates, but I might need to
    if ((brick_type == "brick" || use_ridges_with_plates=="Y") && w > 1)
    {   
        // ridge depth should make up the space lost for interior wall adjusment + add .1mm (Lego play factor) to help it grip
        //TODO: now that I have a good default, make an adjustment for this
        ridge_d = WA + 0.1 - ridge_depth_adjustment;
        //  These ridges can challenge printers; make sure minimum length is 2*nozzle
        ridge_w = LU/2<(2*nozzle_size)?(2*nozzle_size):LU/2;
        
        //For ridge height: print a little larger than stud height.
        // No need to go all the way up. Filiment savings would be tiny,
        //  but print head movement might be noticeable
        // I'm using 1.5LU for convenience... taller than studs, still safe if we use this for plates.     
        LEGO_RIDGES(l, w, ridge_w, ridge_d, LU * 1.5, WT, first_stud, long_wall_l - WT, short_wall_l - WT);
    }
    
    //UNDER-SIDE CENTER SUPPORT POSTS
    LEGO_POSTS(l, w, h, WT, first_stud, nozzle_size, support_post_radius_adjustment);
}

module LEGO_STANDARD(studs_long, studs_wide, brick_type, surface_treatment)
{
    LEGO_FULL(studs_long, studs_wide, brick_type, surface_treatment,
        0, 0, 0, 0, 0, 0, "N");
}

module LEGO_PRINTING_DEFAULTS(studs_long, studs_wide, brick_type, surface_treatment)
{
    LEGO_FULL(length, width, block_type, surface_type,
        wall_adjustment, gap_factor, stud_height_adjustment, stud_radius_adjustment,    support_post_radius_adjustment, ridge_depth_adjustment, "Y"); 
}

LEGO_PRINTING_DEFAULTS(length, width, block_type, surface_type);
