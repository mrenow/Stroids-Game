/* The Lunar Lander
 
 Author: Owen Brasier
 Date: August 2015
 Modified By Ezra Hui, Alex Tan
 */
import java.awt.event.KeyEvent;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;

final float AIR = 0.967;

FastMath math;
Ship ship;

ArrayList<Asteroid> Asteroids = new ArrayList<Asteroid>();
ArrayList<Bullet> projectiles = new ArrayList<Bullet>();
ArrayList<Explosion> bay = new ArrayList<Explosion>();
float CRASHVEL = 0.5;  // threshold for crash velocity
boolean[] keys = new boolean[4];
PImage[] healthbar;
PImage[] enemy;
PImage[] guns;
PImage background;
PVector[] orbit;
boolean shaking;

StartScreen startScreen;
boolean isGameStarted = false; //true if game is started, false if still on start screen

Credits credits;
boolean isCredits = false; //true if credits are showing, false otherwise

float shook;
int cycles = 0;
int deaths = 0;


void setup() {
  //playSound();
  size(1000, 800);
  surface.setTitle("Lunar Lander");  

  //image loading. Will throw exeption if unable to get image.
  try {
    PImage[] bar = {
      loadImage("health09.gif"), 
      loadImage("health08.gif"), 
      loadImage("health07.gif"), 
      loadImage("health06.gif"), 
      loadImage("health05.gif"), 
      loadImage("health04.gif"), 
      loadImage("health03.gif"), 
      loadImage("health02.gif"), 
      loadImage("health01.gif")};
    healthbar = bar;
    for (PImage img : healthbar) {
      img.resize(34, 56);
    }
    PImage[] stroid = {loadImage("sphere00.gif"), 
      loadImage("sphere00.gif")};
    enemy = stroid;
    guns = new PImage[] {loadImage("Gun Turret.png"),loadImage("Laser Turret 2.png")};
    background = loadImage("Space_View.png");
  }
  catch(Exception e) {
    println("Unsucessfully loaded image");
  }
  math = new FastMath(360);
  orbit = new PVector[360];
  for (int i=0; i<orbit.length; i++) {
    orbit[i] = new PVector(math.cosval[i], math.sinval[i]);
  }
  ship = new Ship(new PVector(0, -height/2), 5);
  for (PImage img : healthbar) {
    img.resize(34, 56);
  }
}
void draw() {
  cycles++;
  if (isGameStarted) {
    if (shaking) {
      shake();
    }
    ship.move();
    
    background(background.get(100+(int)(ship.pos.x/10),200+(int)(ship.pos.y/10),width,height));
    translate(width/2, height/2 );
    
    fill(255);
    text("deaths: " + deaths, -width/2, -height/2 + 10);
    //Asteroid draw and loop
    // try{
    for (int i = Asteroids.size()-1; i>=0; i--) {
      Asteroid spacerock = Asteroids.get(i);
      //Handling collisions. Starting from back of list so that object removal is smooth.
      for (int j = i+1; j<Asteroids.size(); j++) {//asteroid-asteroid collision
        Asteroid collision = Asteroids.get(j);
        //if the distance between two points is smaller than their radi combined, execute collision action
        if (pow(spacerock.siz/2 + collision.siz/2, 2) -pow(spacerock.pos.x-collision.pos.x, 2) > pow(spacerock.pos.y-collision.pos.y, 2)) {
          float reflect = atan2(spacerock.pos.y - collision.pos.y, spacerock.pos.x - collision.pos.x);//establishing the angle from collision object to asteroid
          //making sure objects are not inside each other
          PVector move = math.fromAngle(reflect, 0.5);//
          PVector.add(spacerock.pos, move, spacerock.pos);
          move.mult(-1);
          PVector.add(collision.pos, move, collision.pos);
          //changing velocities to new, reflected velocities
          spacerock.vel = reflectSurface(spacerock.vel, reflect);
          collision.vel = reflectSurface(collision.vel, reflect);
        }
      }
      for (int j =projectiles.size()-1; j>=0; j--) { //bullet-asteroid collision
        Bullet bullet = projectiles.get(j);
        if ( (bullet.immunity == null)) {
          if (pow(spacerock.pos.x-bullet.pos.x, 2) + pow(spacerock.pos.y-bullet.pos.y, 2)< pow(spacerock.siz/2, 2)&&random(0, 2)<1) {
  
            spacerock.health--;
            bay.add(new Explosion(bullet.pos, (int)random(15, 25), (int)random(15, 35)));
            if (!bullet.removable) bullet.removable = true;
            if (spacerock.health<=0) {
              if (!spacerock.removable) {
                spacerock.removable = true;
              }
              //Asteroid split action
              int split = floor(random(2, 4));
              spacerock.siz-=10;
              int split2 = split;
              if (spacerock.type != 4) {
                while (split>0 && spacerock.siz > 25) {

                  int siz = floor(spacerock.siz/split);
                  PVector newvel = math.fromAngle(TAU*split/split2, spacerock.vel.mag());
                  PVector newpos = new PVector(spacerock.pos.x+random(-spacerock.siz/8, spacerock.siz/8), spacerock.pos.y+random(-spacerock.siz/8, spacerock.siz/8));
                  spacerock.siz -= siz;
                  Asteroids.add(new Asteroid(newpos, newvel, siz*2, spacerock.armed/2, spacerock.type, floor(random(0,5))));
                  split--;
                }
              } else bay.add(new Explosion(spacerock.pos, spacerock.siz*2, 100));
            }
          }
        }
      }
      PVector[] shipcollision  = {ship.pt[0], midPoint(ship.pt[0], ship.pt[1]), ship.pt[1], midPoint(ship.pt[1], ship.pt[2]), ship.pt[2], midPoint(ship.pt[2], ship.pt[0])};
      for (PVector point : shipcollision) {
        if (pow(spacerock.pos.x-point.x, 2) + pow(spacerock.pos.y-point.y, 2)< pow(spacerock.siz/2, 2)) {
          ship.hit();
          float reflect = atan2(spacerock.pos.y - ship.pos.y, spacerock.pos.x - ship.pos.x);
          PVector relvel = PVector.sub(ship.vel, spacerock.vel);
          ship.vel = reflectSurface(relvel, reflect);
          PVector move = math.fromAngle(reflect, -1);
          ship.pos.add(move);
        }
      }
      spacerock.move();
      spacerock.draw();
      if (spacerock.removable)Asteroids.remove(i);
    }
    for (int i = projectiles.size()-1; i>=0; i--) {
      Bullet bullet = projectiles.get(i);
      bullet.draw();
      if (pow(ship.pos.x-bullet.pos.x, 2) + pow(ship.pos.y-bullet.pos.y, 2)< 144&&!bullet.player) {
        bullet.removable = true;
        bay.add(new Explosion(bullet.pos, (int)random(15, 25), (int)random(15, 35)));
        ship.hit();
        fill(0);
        stroke(0);
      }
      if (bullet.removable)projectiles.remove(i);
    }
    for (int i = bay.size()-1; i>=0; i--) {
      bay.get(i).draw();
      if (bay.get(i).removable)bay.remove(i);
    }
    for (int i = Asteroids.size()-1; i>=0; i--) {
      Asteroids.get(i).drawBar();
    }
    //draw ship over all other objects
    ship.draw();
    
    text(cycles,-width/2,-height/2+30);
  } else {
    startScreen = new StartScreen();
    startScreen.draw();
    //print("test");
  }
  color(255);
}
void shake() {
  shook+=1.5;
  if (shook<7)translate(shook, shook);
  else if (shook<15) translate(10-shook, 10-shook);
  else if (shook<20) translate(shook-20, shook-20);
  else {
    shaking = false;
    shook = 0;
  }
}

/*
ai 
0: tracking
1: Quad
2: Tri

*/
void mousePressed() {
  if (isGameStarted) {
    if (mouseButton == LEFT) {
      Asteroids.add(new Asteroid(new PVector(mouseX-width/2, mouseY-height/2), new PVector(2, 1), 60, 50, Asteroid.STRAFE, 3));
    } else { 
      Asteroids.add(new Asteroid(new PVector(mouseX-width/2, mouseY-height/2), new PVector(2, 1), 200, 10, 4, 0));
    }
    System.out.print("I SUMMON THEE");
  }
}
void keyPressed() {
  if (isGameStarted) {
    switch (keyCode) {
    case KeyEvent.VK_W:
      keys[0] = true;
      break;
    case KeyEvent.VK_A:
      keys[1] = true;
      break;
    case KeyEvent.VK_D:
      keys[2] = true;
      break;
    case KeyEvent.VK_SPACE:
      keys[3] = true;
      break;
    case KeyEvent.VK_Q:
      ship.queue++;
      break;
    case KeyEvent.VK_E:
      ship.queue--;
      break;
    }
  }
}

void keyReleased() {
  if (isGameStarted) {
    switch (keyCode) {
    case KeyEvent.VK_W:
      keys[0] = false;
      break;
    case KeyEvent.VK_A:
      keys[1] = false;
      break;
    case KeyEvent.VK_D:
      keys[2] = false;
      break;
    case KeyEvent.VK_SPACE:
      keys[3] = false;
      break;
    }
  }
}
public void playSound() {
  try {
    AudioInputStream audioInputStream = AudioSystem.getAudioInputStream(new File("C:/Users/My Computer/Downloads/melancholy_-_ezra_asteroid_game.wav").getAbsoluteFile());
    Clip clip = AudioSystem.getClip();
    clip.open(audioInputStream);
    clip.start();
  }
  catch(Exception ex) {
    System.out.println("Error with playing sound.");
    ex.printStackTrace();
  }
}
PVector reflectSurface(PVector incidence, float axis) {
  PVector reflection = incidence.copy();
  reflection.rotate(2*(axis- incidence.heading())+PI);
  return reflection;
}
boolean getSign(float n) {
  if (n < 0)return false;
  return true;
}
PVector midPoint(PVector v1, PVector v2) {
  return new PVector((v1.x+v2.x)/2, (v1.y+v2.y)/2);
};

class StartScreen {


  void draw() {
    background(0, 0, 0);
    translate(width/2, height/2);
    textSize(20);
    text("Press space to start game...", 0, 0);
    text("Press F1 for credits", 0, 50);
    keyPressed();
  }

  void keyPressed() {
    switch (keyCode) {

    case KeyEvent.VK_SPACE:
      if (!isCredits) {
        isGameStarted = true;
        break;
      }
    case KeyEvent.VK_F1:
      isCredits = true;
      credits = new Credits();
      credits.draw();
      break;
    }
  }
}









class Credits {

  void draw() {
    background(0, 0, 0);
    stroke(255, 255, 255);
    text("Credits:\nOriginal author: Owen Brasier\nModified by: Ezra Hui, Alex Tan\nGraphics: Xing Lin\nMusic: Alex Tan", 0, 0);
  }

  void keyPressed() {
    switch (keyCode) {
    case KeyEvent.VK_F1:
      isCredits = false;
    }
  }
}

class Explosion {
  int size;
  float currentsize;
  PVector pos;
  int duration;
  boolean removable;
  boolean expanding;

  Explosion(PVector pos, int size, int duration) {
    this.pos = pos;
    this.size = size;
    this.duration = duration;
    currentsize = 0;
  }


  void draw() {

    duration--;
    if (duration<10) {
      currentsize-=(float)size/10;
    } else if (currentsize<size*0.8) {
      currentsize+=(float)size/10;
    } else if (expanding) {
      currentsize+=(float)size/40;
      if (currentsize>size*1.15)expanding = false;
    } else {
      currentsize-=(float)size/40;
      if (currentsize<size*0.85)expanding = true;
    }
    removable = duration==0;
    fill(255, 100, 0);
    stroke(255, 50, 0);
    strokeWeight(size/30);
    ellipse(pos.x, pos.y, currentsize/2, currentsize/2);
    noStroke();
    fill(255, 150, 0);
    ellipse(pos.x, pos.y, currentsize/4, currentsize/4);
  }
}
class Bullet {
  PVector pos;
  PVector vel;
  boolean removable = false;
  boolean explodable;
  boolean player;
  int bounce;
  Object immunity;

  Bullet(PVector pos, float theta, int bounce, float speed, boolean explodable, boolean player, Object immunity) {
    this.pos = pos.copy();
    vel = math.fromAngle(theta + random(-0.01, 0.01), speed);
    this.bounce = bounce;
    this.explodable = explodable;
    this.player = player;
    this.immunity = immunity;
  }
  Bullet(PVector pos, PVector vel, float theta, int bounce, float speed, boolean explodable, boolean player, Object immunity) {
    this.pos = pos.copy();
    this.vel = math.fromAngle(theta, speed);
    this.vel.add(vel);
    this.bounce = bounce;
    this.explodable = explodable;
    this.player = player;
    this.immunity = immunity;
  }
  void draw() {
    strokeWeight(2);
    //if bullet is fired by player, make bullet red
    if (player) {
      stroke(255, 50, 50);
    } else {
      //if bullet is fired by an asteroid, make bullet white
      stroke(255, 255, 255);
    }

    line(pos.x, pos.y, pos.x+vel.x, pos.y+vel.y);
    move();
  }
  void move() {

    if (Math.abs(pos.x) >= width/2) {
      if (bounce>0) {
        vel.x *= -1;

        bounce--;
      } else removable = true;
    }

    if (Math.abs(pos.y) >= height/2) {
      if (bounce>0) {

        vel.y *= -1;
        bounce--;
      } else removable = true;
    }

    pos.x += vel.x;
    pos.y += vel.y;
  }
}
class Asteroid {
  static final int TRACK = 0, T4 = 1, T3 = 2, SPIN=3, T2_SPIN=4;
  static final int BURST = 1, CONST = 2, RAND = 3, MOTHER = 4,SHOT = 5,STRAFE =6;
  Asteroid parent;
  PVector pos;
  float[] turretang;
  PVector[] turretpos;
  PVector vel;
  PVector[] path;
  int siz;
  int maxhealth;
  int health;
  boolean removable = false;
  boolean side;
  int armed =0; //functions either as a value of how armed the enemy is, or whether to deploy an orbiter of not
   int type;
  int ai; // turret positions
  int lights;
  final int TIME; //Time of creation


  Asteroid(PVector pos, PVector vel, int siz, int armed, int type, int ai) {
    this(siz,armed,type,ai);  
    this.pos = pos;
    this.vel = vel;
    maxhealth = (int)Math.pow(siz,1.5)/40;
    if(type == 4) maxhealth*=1.5;
    health = maxhealth;
    parent = this;
  
  }
  Asteroid(Asteroid parent, boolean side, int siz, int armed, int type, int ai) {
    this(siz,armed,type,ai);
    vel = new PVector(0, 0);
    maxhealth = (int)(parent.health*random(0.4,0.7)/5);
    health = maxhealth;
    this.side = side;
    pos = new PVector(parent.pos.x+(parent.siz+siz)*(side?0.5:-0.5), parent.pos.y);
    this.parent = parent;
    path = new PVector[orbit.length];
    for (int i=0; i<orbit.length; i++) {
      path[i] = orbit[i].copy();
      path[i].mult(parent.siz+siz/2);
    }
  }
  Asteroid(int siz, int armed, int type, int ai){
    this.siz = siz;
    this.armed = armed;
    this.type = type;
    this.ai = ai;
    TIME = cycles;
    switch(ai) {
    case 0:
      turretpos = new PVector[]{new PVector(1, 1)};
      turretang = new float[1];
      break;
    case 1:
      turretang = new float[] {PI, 0, -PI, TAU};
      turretpos = new PVector[] {new PVector(siz/2, 0), new PVector(0, -siz/2), new PVector(-siz/2, 0), new PVector(0, siz/2)};
      break;
    case 2:
      //print("yes!");
      turretang = new float[] {-TAU/3, 0, TAU/3};
      turretpos = new PVector[] {math.fromAngle(-TAU/3, siz/2), math.fromAngle(0, siz/2), math.fromAngle(TAU/3, siz/2)};
      break;
    case 3:
      turretpos = new PVector[]{new PVector(1, 1)};
      turretang = new float[1];
      break;
  
    
    case 4:
      turretpos = new PVector[]{new PVector(1, 1),new PVector(1, 1)};
      turretang = new float[2];
      break;
    }
    
    
  }
  void draw() {
    image(enemy[0], pos.x-siz/2, pos.y-siz/2, siz, siz);
  //  ellipse(pos.x, pos.y, siz, siz);
    
    fill(255, 30, 0);
    stroke(255, 0, 0);
    switch(lights) {
    case 1:
      rect(pos.x-siz/3, pos.y+siz/6, siz/50, siz/50);
      break;
    case 5:
      rect(pos.x, pos.y+siz/6, siz/50, siz/50);
      break;
    case 9:
      rect(pos.x+siz/3, pos.y+siz/6, siz/50, siz/50);
      break;
    case 13:
      rect(pos.x-siz/3, pos.y-siz/6, siz/50, siz/50);
      break;
    case 17:
      rect(pos.x, pos.y-siz/6, siz/50, siz/50);
      break;
    case 21:
      rect(pos.x+siz/3, pos.y-siz/6, siz/50, siz/50);
      break;
    case 24:
      lights = 0;
      break;
    }
    strokeWeight(1);
    stroke(0);
    fill(50);
    
    
  }
  void move() {
    if (parent == this) { //IF NORMAL ASTEROID
      //BOUNCE ON y AyIS UPON COLLISION WITH CIRCLE
      if (Math.abs(pos.x) + siz/2 >= width/2) {
        vel.x *= -1;
        pos.x += -(getSign(pos.x)?(pos.x+siz/2) - width/2 + 1:(pos.x-siz/2) + width/2 - 1);
        //Wall collision event
      }
      //BOUNCE ON Y AyIS UPON COLLISION WITH CIRCLE (Only on ceiling)
      if (Math.abs(pos.y) + siz/2 >= height/2) {
        vel.y *= -1;
        pos.y += -(getSign(pos.y)?(pos.y+siz/2) - height/2 + 1:(pos.y-siz/2) + height/2 - 1);
        //Wall collision event
      }
      PVector.add(pos, vel, pos);//NORMAL ASTEROID SEQUENCE END
    } else if (cycles-TIME>30) {//IF ORBITER
      if ((((cycles-TIME)/2)%path.length==0)) {
        parent.armed = 0;
      }

      PVector oldpos = pos.copy();
      pos = PVector.add(parent.pos, path[(((cycles-TIME)/2+path.length-15))%path.length]);
      vel = PVector.sub(pos, oldpos);
      if (parent.removable) {
        float rand = random(0, 50);
        if (rand>45) {
          bay.add(new Explosion(new PVector(pos.x+random(-siz/2,siz/2),pos.y+random(-siz/2,siz/2)),(int)random(5,20),(int)random(10,100)));
          health -= floor(pow(random(0,1.4),6));
          if(health<0) removable = true;
        }
      }
    } else {
      pos.x+=parent.siz*0.5/30*(side?1:-1);
      pos.add(parent.vel);
    }//ORBITER SEQUENCE END

    //TURRET CALCULATION
    print(ai);
    updateTurrets();

    switch(type) {
    //
    case 1:
      if ((cycles-TIME)%1==0&&(cycles-TIME)%115<armed*20) {
        for (int i=0; i<turretpos.length; i++) {
          projectiles.add(new Bullet(PVector.add(turretpos[i], pos), vel, turretang[i], 1, 20, true, false, parent));
        }
      }
      break;
    case 2:
      if ((cycles-TIME)%ceil(100.0/(armed+1))==0) {
        for (int i=0; i<turretpos.length; i++) {
           projectiles.add(new Bullet(PVector.add(turretpos[i], pos), vel, turretang[i], 1, 10, true, false, parent));
        }
      }
      break;
    case 3:
      if ((cycles-TIME)%(int)random(30, 40)==0) {
        for (int i=0; i<turretpos.length; i++) {
          projectiles.add(new Bullet(PVector.add(turretpos[i], pos), turretang[i], 0, 10, true, false, parent));
        }
      }
      break;

    case 4:
      if ((cycles-TIME)%20==0) {
        if (armed == 1) Asteroids.add(new Asteroid(this, true, 50, 1, 6, 0));
        lights++;
      } else if ((cycles-TIME)%20==19) {
        armed = 1;
      }
      break;
    case 5:
      if((cycles-TIME)%ceil(100.0/(armed+1)) == 0){
       for (int i=0; i<turretpos.length; i++) {
          for(int j = 0; j<armed;j++)   projectiles.add(new Bullet(PVector.add(turretpos[i], pos), vel, turretang[i]+random(-0.04,0.04), 1, 5, true, false, parent));
        }
      }
    case 6: 
      if((cycles-TIME)%ceil(200.0/(armed+1)) == 0){
        for(int i = 0; i<turretpos.length;i++) projectiles.add(new Bullet(PVector.add(turretpos[i], pos), vel, turretang[i]+random(-0.04,0.04), 0, 5, true, false, parent));
      }
       
    }
  }

  void updateTurrets() {
    switch(ai) {
    case 0:
      PVector rpos = PVector.sub(ship.pos,pos) ;
      PVector rvel = PVector.sub(ship.vel,vel);
      float dist2 = rpos.x*rpos.x + rpos.y*rpos.y;
      float a = rvel.x*rpos.y - rvel.y*rpos.x;
      
      float det = 400*dist2-a*a;
      if(det<0) det = 0;
      else det = sqrt(det);
      float b = rpos.y*a+rpos.x*det;
      float c = -rpos.x*a+rpos.y*det;
      
      turretang[0] = atan2(c,b);
      turretpos[0] = turretpos[0].set(siz/2*math.cos(turretang[0]), siz/2*math.sin(turretang[0]));
      break;

    case 1:
      if (turretang[0]!=-PI/2) {
        print("yes!");
        turretang = new float[] {PI/2, 0, -PI/2, PI};
        turretpos = new PVector[] {new PVector(0, siz/2), new PVector(siz/2, 0), new PVector(0, -siz/2), new PVector(-siz/2, 0)};
      }
      break;
    case 2:
      if (turretang[0]!=-TAU/3) {
        print("yes!");
        turretang = new float[] {-TAU/3, 0, TAU/3};
        turretpos = new PVector[] {math.fromAngle(-TAU/3, siz/2), math.fromAngle(0, siz/2), math.fromAngle(TAU/3, siz/2)};
      }
      break;
    case 3:
      turretang = new float[] {(float)(cycles - TIME)/6};
      turretpos = new PVector[] {math.fromAngle(turretang[0],siz/2)};
   
    case 4:
      float ang = (float)(cycles-TIME)/6;
      turretang = new float[] {ang,ang+PI};
      turretpos = new PVector[] {math.fromAngle(turretang[0],siz/2),math.fromAngle(turretang[1],siz/2)};
    }
     
  }
  void drawBar(){
    float percentage = (float)health/maxhealth;
    colorMode(HSB,3);
    fill(percentage,3,3);
    noStroke();
    
    rect(pos.x-maxhealth/2,pos.y+siz/2,health,3);
    colorMode(RGB,255);
  
  
  }
}

class Ship {
  
  PVector pos;   // position
  PVector vel;
  float theta;   // rotation angle
  float angularvel;
  PVector[] tr;  // thruster
  int siz;       // size
  PVector[] pt;  // shape
  boolean thruster;
  boolean switchable;
  int health;
  int invincible;
  int reloading;
  int weapon;
  int queue;
  int ammo;
  int burst;
  float thrust;
  final float THRUST;

  Ship(PVector pos, int siz) {
    this.pos = pos;
    this.siz = siz;
    //vel = new PVector(0, 0);
    vel = new PVector(0, 0);
    // the ship has its nose upwards
    theta = -PI/2;
    pt = new PVector[4];
    tr = new PVector[4];
    thruster = false;
    health = 8;
    invincible = 0;
    updatePoints();
    angularvel=0;
    weapon = 0;
    queue = 0;
    burst = 0;
    switchable = true;
    ammo = 100;
    THRUST = 0.35;
  }

  /*
  ** determine if we have landed, if so return whether crash or successful
   */
  int hit() {
    if (invincible < 0) {
      shaking = true;
      //print("UDIDE");
      invincible = 35;
      health--;
    }


    return 0;
  }

  /**
   * display the ship on screen
   */
  void draw() {
    strokeWeight(1);
    stroke(0);
    fill(125);
    triangle(pt[0].x, pt[0].y, pt[1].x, pt[1].y, pt[2].x, pt[2].y);
    image(healthbar[health], ship.pos.x-healthbar[health].width, ship.pos.y-healthbar[health].height/2 -5);
    if (thruster) {
      tr[0] = PVector.lerp(pt[1], pt[2], 0.25);            // sides of flame 0.25 and 0.75 between the base of the ship
      tr[1] = PVector.lerp(pt[1], pt[2], 0.75);
      PVector middle = PVector.lerp(pt[1], pt[2], 0.5);    // middle of the base
      tr[2] = PVector.lerp(middle, pt[0], -1.5);           // point of the red flame
      tr[3] = PVector.lerp(middle, pt[0], -0.5);           // point of the orange flame
      noStroke();
      fill(255, 0, 0);
      triangle(tr[0].x, tr[0].y, tr[1].x, tr[1].y, tr[2].x, tr[2].y);
      fill(255, 102, 0);
      triangle(tr[0].x, tr[0].y, tr[1].x, tr[1].y, tr[3].x, tr[3].y);
    }
  }
  void move() {
    ship.thruster = keys[0];
    theta = atan2(mouseY-pos.y-height/2, mouseX-pos.x-width/2);
    if (pow(mouseY-height/2-pos.y, 2) + pow(mouseX-width/2-pos.x, 2) <6400)
      if (pow(mouseY-height/2-pos.y, 2) + pow(mouseX-width/2-pos.x, 2)<64)thrust=0.;
      else thrust= (pow(mouseY-height/2-pos.y, 2) + pow(mouseX-width/2-pos.x, 2))/6400*THRUST;
    else thrust = THRUST;
    //println(thrust);
    vel.mult(AIR);
    if (thruster) {
      vel.y += thrust*math.sin(theta);
      vel.x += thrust*math.cos(theta);
    }

    //BOUNCE CODE
    //BOUNCE ON X AXIS UPON COLLISION WITH POINTS OF TRIANGLE
    if (Math.abs(pt[0].x) >= width/2) {
      vel.x *= -1;
      pos.x += -(getSign(pt[0].x)?pt[0].x - width/2 + 1:pt[0].x + width/2 - 1);
    } else if (Math.abs(pt[1].x) >= width/2) {
      vel.x *= -1;
      pos.x += -(getSign(pt[1].x)?pt[1].x - width/2 + 1:pt[1].x + width/2 - 1);
    } else if (Math.abs(pt[2].x) >= width/2) {
      vel.x *= -1;
      pos.x += -(getSign(pt[2].x)?pt[2].x - width/2 + 1:pt[2].x + width/2 - 1);
    }
    //BOUNCE ON Y yAyIS UPON COLLISION WITH POINTS OF TRIANGLE (Only on ceiling)
    if (Math.abs(pt[0].y) >= height/2) {
      vel.y *= -1;
      pos.y += -(getSign(pt[0].y)?pt[0].y - height/2 + 1:pt[0].y + height/2 - 1) ;
    } else if (Math.abs(pt[1].y) >= height/2) {
      vel.y *= -1;
      pos.y += -(getSign(pt[1].y)?pt[1].y - height/2 + 1:pt[1].y + height/2 - 1) ;
    } else if (Math.abs(pt[2].y) >= height/2) {
      vel.y *= -1;
      pos.y += -(getSign(pt[2].y)?pt[2].y - height/2 + 1:pt[2].y + height/2 - 1);
    }




    //
    if (vel.mag()>20) {
      vel.setMag(20);
    }
    //keep top speed at 15 px
    // move the ship in x and y
    pos.add(vel);
    updatePoints();
    theta += angularvel/100;
    angularvel*=0.9;
    if (keys[2])angularvel+=0.5;
    if (keys[1])angularvel-=0.5;
    //Timers
    reloading--;
    invincible--;
    //detectors
    switchable = !(burst>0);//atm, switchable is synonymous with burst being zero
    //print(projectiles.size()+"    ");
    if (ammo<700)if (reloading>0||ammo<0)ammo+=1000;
    else ammo+=400;
    if (switchable) {
      weapon = queue%6;
    }
    if (((keys[3]  && ammo>0)||!switchable )&& reloading < 0) {
      switch(weapon) {
      case 0:
        if (switchable) {
          burst = 10;
          ammo -= 170;
        } else {
          reloading = 1 ;
          burst--;
          projectiles.add(new Bullet(pos, theta, 2, 10, true, true, null));
          if (burst == 0) reloading = 20;
        }
        break;


      case 1:
        projectiles.add(new Bullet(pos, theta, 2, 10, false, true, null));
        reloading = 3;
        ammo-=20;
        break;


      case 2:
        projectiles.add(new Bullet(pos, theta+0.09, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta+0.06, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta+0.03, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta-0.03, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta-0.06, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta-0.09, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta-0.012, 4, 10, false, true, null));
        projectiles.add(new Bullet(pos, theta+0.012, 4, 10, false, true, null));
        reloading = 30;
        ammo -= 250;
        break;

//      case 3:
 //       for(int i = 0; i<200; i++) projectiles.add(new Bullet(pos, theta+random(-0.07, 0.07), 1, 0.8, false, true, null));
  //      ammo-=40;
   //   reloading = 0;
    //    break;

      case 3:
        if (switchable) {
          burst = 10;
          ammo -= 250;
        } else {
          reloading = 0 ;
          burst--;
          projectiles.add(new Bullet(pos, theta, 2, 10, false, true, null));
          projectiles.add(new Bullet(pos, theta, 2, 10.01, false, true, null));
          if (burst == 0) reloading = 20;
        }
        break;
      case 4:
        projectiles.add(new Bullet(pos, 0.1*cycles, 0, 20, false, true, null));
        reloading = 0;
        break;
      }
    } else {
      //playsound here
    }
    //if you are very deceased
    if (health <= 0) {
      deaths++;
      //change this later to death screen or something

      health = 8;
    }
  }

  /* Note the origin (0, 0) is the center of the screen
   So the top has a y value of -height/2
   The left has an x value of -width/2
   We can get the x position by using pos.x
   And the y position by pos.yczxc
   */


  /**
   * calculate the coordinates of the shape
   */
  void updatePoints() {
    // nose
    pt[0] = new PVector(pos.x+siz*math.cos(theta), pos.y+siz*math.sin(theta));
    // bottom left
    pt[1] = new PVector(pos.x+1.7*siz*math.cos(theta+(PI+0.7)), pos.y+1.7*siz*math.sin(theta+(PI+0.7)));
    // bottom right
    pt[2] = new PVector(pos.x+1.7*siz*math.cos(theta+(PI-0.7)), pos.y+1.7*siz*math.sin(theta+(PI-0.7)));
  }
}
/*
 Imported Fastmath class to speed up sin and cos calculations
 
 Added functions for PVector calculation.
 
 Author: Ezra Hui
 */
public class FastMath {
  float sinval[];
  float cosval[];
  int accuracy;
  public FastMath(int accuracy) {
    this.accuracy = accuracy;
    sinval = new float[this.accuracy+1];
    cosval = new float[this.accuracy+1];
    for (int i = 0; i <accuracy+1; i++) {
      sinval[i] = (float)Math.sin((float)(i*TAU/(accuracy)));
      cosval[i] = (float)Math.cos((float)(i*TAU/(accuracy)));
    }
  }
  //native methods
  public float sin(float x) {
    x = (x%TAU);
    while (x<0)x+=TAU;
    x *= accuracy/TAU;
    float sinflor = sinval[(int)Math.ceil(x)];
    float val = sinflor+(sinval[(int)Math.floor(x)]-sinflor)*(x%1);
    if (x<0) {
      val*=-1;
    }
    return val;
  }
  public float cos(float x) {
    x = (x%TAU);
    while (x<0) x+=TAU;
    x *= accuracy/TAU;
    float cosflor = cosval[(int)Math.ceil(x)];
    float val = cosflor+(cosval[(int)Math.floor(x)]-cosflor)*(x%1);
    if (x<0) {
      val*=-1;
    }
    return val;
  }
  //PVector methods
  PVector fromAngle(float theta, float mag) {
    return new PVector(this.cos(theta)*mag, this.sin(theta)*mag);
  }
  PVector fromAngle(float theta) {
    return new PVector(this.cos(theta), this.sin(theta));
  }
}