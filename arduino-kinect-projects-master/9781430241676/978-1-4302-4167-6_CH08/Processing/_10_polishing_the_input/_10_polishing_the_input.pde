import processing.opengl.*;
import SimpleOpenNI.*;
SimpleOpenNI kinect;

PVector pointer = new PVector();
PVector [] path = new PVector[100]; //we're declaring array of 100 points

float        zoomF = 0.3f;
float        rotX = radians(180); 
float        rotY = radians(0);


float        zCutOffDepth = 750;
float        tableRotation = -1.0;


void setup()
{
  size(1024, 768, OPENGL);  
  kinect = new SimpleOpenNI(this);
  kinect.setMirror(false);	// disable mirror
  kinect.enableDepth();	// enable depthMap generation 
  perspective(95, float(width)/float(height), 10, 150000);

  //allocate memory for our path
  for(int i = 0; i < 100; i++){
     path[i] = new PVector();
  }


}

//Within the draw() function, we will update the Kinect data, and then we will set the perspective settings using the functions rotateX(), rotateY() and scale().

void draw()
{
  kinect.update();   // update the cam
  background(255);
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);

// Then, we will declare and initialize the necessary variables for the drawing of the point cloud, as we have done in other projects.

  int[]   depthMap = kinect.depthMap(); // tip – this line will throw an error if your Kinect is not connected
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

// We will set the rotation center of the scene for visual purposes 1000 in front of the camera, which is close to the distance from the Kinect to the center of the table.

  translate(0, 0, -1000);  
  stroke(0);

  PVector[] realWorldMap = kinect.depthMapRealWorld();
  PVector newPoint = new PVector();

//To make things clearer, let’s mark a point that is in on Kinect’s z-axis (so it’s X and Y are equal to 0). This code is using realWorldMap array, which is an array of 3d coordinates of each screen point, and we’re simply choosing the one that is in the middle of the screen (hence depthWidth/2 and depthHeight/2). As we are in coordinates of Kinect, where (0,0,0) is the sensor itself, we are sampling the depth there, and placing the red cube using the function drawBox(), that we will implement later.

  index = kinect.depthWidth()/2 + kinect.depthHeight()/2 * kinect.depthWidth();
  float pivotDepth = 875;
  fill(255,0,0);
  drawBox(0, 0, pivotDepth, 50);  

  float maxDepth = 0;


  for(int y=0; y < kinect.depthHeight(); y+=steps)
  {
    for(int x=0; x < kinect.depthWidth(); x+=steps)
    {
      index = x + y * kinect.depthWidth();
      if(depthMap[index] > 0)
      { 
        realWorldPoint = realWorldMap[index];
        realWorldPoint.z -= pivotDepth;
        
        float ss = sin(tableRotation);
        float cs = cos(tableRotation);
        
        newPoint.x = realWorldPoint.x;
        newPoint.y = realWorldPoint.y*cs - realWorldPoint.z*ss;
        newPoint.z = realWorldPoint.y*ss + realWorldPoint.z*cs + pivotDepth;

        if ((newPoint.z > zCutOffDepth - 50) && 
            (newPoint.z < zCutOffDepth) && 
            (newPoint.x < 400) && 
            (newPoint.x > -400) && 
            (newPoint.y < 300) && 
            (newPoint.y > -300)) {
            point(newPoint.x, newPoint.y, newPoint.z); 
            if (newPoint.z>maxDepth) //store deepest point found
            {
              maxDepth = newPoint.z;
              pointer.x = newPoint.x;
              pointer.y = newPoint.y;
              pointer.z = newPoint.z;
            }

        }
      }
    }
  } 
  
  //let's display our pointer
  fill(255,255,0); //choose yellow color
  drawBox(pointer.x,pointer.y,pointer.z,50);



  //following four lines will display our table area
  
  line(-400, -300, pivotDepth,  400, -300, pivotDepth);
  line(-400,  300, pivotDepth,  400,  300, pivotDepth);
  line( 400, -300, pivotDepth,  400,  300, pivotDepth);
  line(-400, -300, pivotDepth, -400,  300, pivotDepth);

  path[frameCount % 100].x = pointer.x;
  path[frameCount % 100].y = pointer.y;


  //===========================
  //we're drawing the robot now
  //===========================  
  float robotX = 0;
  float robotY = -300;

  pushMatrix();

      translate(0, 0, pivotDepth);
      ellipse(robotX, robotY, 30, 30); 
      ellipse(pointer.x, pointer.y, 30, 30); 
      line(robotX, robotY, pointer.x, pointer.y);

      for (int i = 0; i < 100; i++){
        ellipse(path[i].x, path[i].y, 5, 5);
      }

      float penX = 0; //we're resetting pen coordinates
      float penY = 0;
      //and adding fractions of 20 last positions to them
      for (int i = 0; i < 20; i++) { 
        penX += path[(frameCount + 100 - i) % 100].x/20.0;
        penY += path[(frameCount + 100 - i) % 100].y/20.0;
      }

      float len = dist(robotX, robotY, penX, penY); //let's measure the length of our line
      float angle = asin((penY-robotY)/len); //asin returns angle value in range of 0 to PI/2, in radians
      if (penX<0) { angle = PI - angle; } // this line makes sure angle is greater than PI/2 (90 deg) when penX is negative
      println("angle = " + degrees(angle)); //we're outputting angle value converted from radians to degrees
      println("length = " + len);//print out the length 
      arc(robotX, robotY, 200, 200, 0, angle); //let's draw our angle as an arc
      if (len > 450) { len = 450; }
      if (len < 150) { len = 150; }
      
      float dprime = (len - 150) / 2.0;
      float a = acos(dprime / 150);
      float angle3 = angle + a;
      float angle2 = - a;
      float angle1 = - a;
      
      translate( robotX, robotY );
      rotate(angle3);
      line(0, 0, 150, 0);
      translate(150, 0);
      
      rotate(angle2);
      line(0, 0, 150, 0);
      translate(150, 0);
      
      rotate(angle1);
      line(0, 0, 150, 0);
      translate(150, 0);

  popMatrix();




// Now, we will display the value of our tableRotation

  println("tableRot = " + tableRotation);

// and z cut-off depth

  println("cutOffDepth = " + zCutOffDepth);

  kinect.drawCamFrustum();   // draw the kinect cam
}

//Within the KeyPressed() callback function, we will add code that will react to pressing key 1 and 2, changing the values of tableRotation by small increments/decrements. We will also be listening for input from the arrow keys to change the point of view.

void keyPressed()
{
  switch(key)
  {
  case '1':
    tableRotation -= 0.05;
    break;
  case '2':
    tableRotation += 0.05;
    break;
  }

  switch(keyCode)
  {
    case LEFT:
      rotY += 0.1f;
      break;
    case RIGHT:
      // zoom out
      rotY -= 0.1f;
      break;
    case UP:
      if(keyEvent.isShiftDown())
      {
        zoomF += 0.02f;
      }
      else
      {
        rotX += 0.1f;
      }
      break;
    case DOWN:
      if(keyEvent.isShiftDown())
      {
        zoomF -= 0.02f;
        if(zoomF < 0.01)
          zoomF = 0.01;
      }
      else
      {
        rotX -= 0.1f;
      }
      break;
    case '3':
      zCutOffDepth -= 5;
      break;
    case '4':
      zCutOffDepth += 5;
      break;

  }
}

void drawBox(float x, float y, float z, float size)
{
  pushMatrix();
    translate(x, y, z);
    box(size);
  popMatrix();
}

