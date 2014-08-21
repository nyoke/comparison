import java.io.File;

final int devide = 10;

PImage img = null;
int LENGTH;
String [][] csv;
String path;
boolean init = false;
PGraphics divied, eye, propose, saliency, over;
  
/* For comparison */
ROI saliency   = new ROI();
ROI subjective = new ROI();
ROI proposed   = new ROI();
boolean[][] cell_saliency = new boolean[devide][devide];
boolean[][] cell_subjective = new boolean[devide][devide];
boolean[][] cell_proposed = new boolean[devide][devide];

/* Container of ROI data */
class ROI
{
  ArrayList x = new ArrayList();
  ArrayList y = new ArrayList();
  ArrayList duration = new ArrayList();
  public int total;

  public void add(int x, int y, double duration)
  {
    total++;
    this.x.add(x);
    this.y.add(y);
    this.duration.add(duration);
    println("x:" + x + " y:" + y + " duration:" + duration);
  }

  public int get_x(int index)
  {
    if ( total < index ) println("error");
    return (Integer)x.get(index);
  }

  public int get_y(int index)
  {
    if ( total < index ) println("error");
    return (Integer)y.get(index);
  }

  public double get_duration(int index)
  {
    if ( total < index ) println("error");
    return (Double)duration.get(index);
  }
}

/* Main routin */
void setup()
{
  size(1024, 768);
  selectInput("Select a file to process:", "fileSelected");
}

void draw()
{
  if ( img != null)
  {
    int dx = width / 2 - img.width / 2;
    int dy = height / 2 - img.height / 2;

    image(pg, dx, dy);

    /*

     for (int i=1; i< LENGTH; i++) {
     x = Integer.parseInt(csv[i][0]);
     y = Integer.parseInt(csv[i][1]);
     r = Integer.parseInt(csv[i][2]);
     println("i = " + i + " (" + x + ", " + y + ")" + "r = " + r);
     ellipse(x+dx, y+dy, r / 500 + 2, r / 500+2);
     }
     */
  }
}

void fileSelected(File selection)
{
  noLoop();
  if (selection != null) 
  {
    path = selection.getAbsolutePath();
    //println(path);    
    img = loadImage(path);
    if ( img == null ) return; // error

    // parse of file path
    int lastPosition = path.lastIndexOf('.');
    if (lastPosition > 0)
      path = path.substring(0, lastPosition);

    /* calculation of additional margin */
    int pad_x = devide - img.width  % devide;
    int pad_y = devide - img.height % devide;

    int top, bottom, left, right;
    top  = bottom = pad_x / 2;
    left = right  = pad_y / 2;

    if ( pad_x % 2 != 0)
      top++;
    if ( pad_y % 2 != 0)
      left++;

    println("[imagesize: " + img.width + " * " + img.height + "]");
    println("[additon  : " + top + ", " + bottom + ", " + left + ", " + right + "]");

    int pg_width = img.width + top + bottom;
    int pg_height = img.height + left + right;
    int cell_width = pg_width / devide;
    int cell_height = pg_height / devide;

    println("[pgsize   : " + pg_width + " * " + pg_height + "]");
    println("[cellsize : " + cell_width + " * " + cell_height + "]");
    pg = createGraphics(pg_width, pg_height);

    /********************************************************/
    /* Reading saliency map data                            */
    String lines[] = loadStrings(path + "-sali.tsv");

    int csvWidth=0;
    for (int i=0; i < lines.length; i++)
    {
      String [] chars=split(lines[i], '\t');
      if (chars.length>csvWidth)  csvWidth=chars.length;
    }

    csv = new String [lines.length][csvWidth];
    LENGTH =lines.length;
    //println("csv size = " + csvWidth + " × " + LENGTH);
    for (int i=0; i < lines.length; i++)
    {
      String [] temp = new String [lines.length];
      temp= split(lines[i], '\t');
      for (int j=0; j < temp.length; j++)
      {
        csv[i][j]=temp[j];
      }
    }

    double last_time = 0.0;
    for ( int i = 0; i < LENGTH; i++)
    {
      //println(csv[i][1]);
      if ( csv[i][1].equals("CovertShift") )
      {
        String[] tmp = csv[i][2].split(",");
        String[] tmp_left = tmp[0].split("\\(");
        String[] tmp_right = tmp[1].split("\\)");

        int x = Integer.parseInt(tmp_left[1]);
        int y = Integer.parseInt(tmp_right[0]);

        double time = Double.parseDouble(csv[i][0].substring(0, csv[i][0].length() - 2));

        saliency.add(x + top, y + left, time - last_time);
        last_time = time;
      }
    }

    /********************************************************/
    /* Reading proposed detection data  */
    lines = loadStrings(path + "-point.csv");

    csvWidth=0;
    for (int i=0; i < lines.length; i++)
    {
      String [] chars=split(lines[i], ',');
      if (chars.length>csvWidth)  csvWidth=chars.length;
    }

    csv = new String [lines.length][csvWidth];
    LENGTH =lines.length;
    println("csv size = " + LENGTH + " × " + csvWidth);

    for (int i=0; i < lines.length; i++)
    {
      String [] temp = new String [lines.length];
      temp= split(lines[i], ',');
      for (int j=0; j < temp.length; j++)
      {
        csv[i][j]=temp[j];
      }
    }

    for ( int i = 0; i < LENGTH; i++)
    {
      int x = Integer.parseInt(csv[i][0]);
      int y = Integer.parseInt(csv[i][1]);
      proposed.add(x + top, y + left, -1);
    }

    /********************************************************/
    /* Reading human eye fixation data (which is subjective data)  */
    lines = loadStrings(path + "-subjective.csv");

    csvWidth=0;
    for (int i=0; i < lines.length; i++)
    {
      String [] chars=split(lines[i], ',');
      if (chars.length>csvWidth)  csvWidth=chars.length;
    }

    csv = new String [lines.length][csvWidth];
    LENGTH =lines.length;
    println("csv size = " + LENGTH + " × " + csvWidth);

    for (int i=0; i < lines.length; i++)
    {
      String [] temp = new String [lines.length];
      temp= split(lines[i], ',');
      for (int j=0; j < temp.length; j++)
      {
        csv[i][j]=temp[j];
      }
    }

    for ( int i = 0; i < LENGTH; i++)
    {
      int x = Integer.parseInt(csv[i][0]);
      int y = Integer.parseInt(csv[i][1]);
      subjective.add(x + top, y + left, -1);
    }

    /********************************************************/
    /* draw each fixation points */
    divied.beginDraw();
    eye.beginDraw();
    propose.beginDraw();
    saliency.beginDraw();
    over.beginDraw();
    
    pg2.tint(160);
    pg3.tint(160);
    
    divied.image(img, top, left);
    eye.image(img, top, left);
    propose.image(img, top, left);
    saliency.image(img, top, left);
    over.image(img, top, left);
    
    divied.noTint();
    eye.noTint();
    propose.noTint();
    
    pg.stroke(255, 255, 255);
    pg2.stroke(255, 255, 255);
    pg3.stroke(255, 255, 255);
    for (int x = cell_width; x <= pg_width; x += cell_width)
    {
      pg.line(x, 0, x, pg_height);
      pg2.line(x, 0, x, pg_height);
      pg3.line(x, 0, x, pg_height);
    }

    for (int y = cell_height; y <= pg_height; y += cell_height)
    {
      pg.line(0, y, pg_width, y);
      pg2.line(0, y, pg_width, y);
      pg3.line(0, y, pg_width, y);
    }
      
    pg.endDraw();
    pg.save(path + "-divide.png");
    pg.beginDraw();

    // saliency map
    pg.stroke(255, 0, 0);
    pg.fill(255, 0, 0, 98);
    for ( int i = 1; i < saliency.total; i++)
      pg.ellipse(saliency.get_x(i), saliency.get_y(i), 10, 10);

    // human eye fixations
    pg.stroke(0, 255, 0);
    pg.fill(0, 255, 0, 98);
    for ( int i = 1; i < subjective.total; i++)
      pg.ellipse(subjective.get_x(i), subjective.get_y(i), 10, 10);

    // proposed model detection
    pg.stroke(0, 0, 255);
    pg.fill(0, 0, 255, 98);
    for ( int i = 1; i < proposed.total; i++)
      pg.ellipse(proposed.get_x(i), proposed.get_y(i), 10, 10);

    //detection
    for ( int x = 0; x < devide; x++)
    {
      for ( int y = 0; y < devide; y++)
      {
        /* saliency *****/
        pg.stroke(255, 0, 0);
        pg.fill(255, 0, 0, 95);
        for ( int i = 0; i < saliency.total; i++)
        {
          if ( (saliency.get_x(i) > (x * cell_width)) && (saliency.get_x(i) < ( (x+1) * cell_width)))
          {
            if ( (saliency.get_y(i) > (y * cell_height)) && (saliency.get_y(i) < ( (y+1) * cell_height)))
            {
              //pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
              cell_saliency[x][y] = true;
            }
          }
        }
        /* subjective *****/
        pg.stroke(0, 255, 0);
        pg.fill(0, 255, 0, 95);
        for ( int i = 0; i < subjective.total; i++)
        {
          if ( (subjective.get_x(i) > (x * cell_width)) && (subjective.get_x(i) < ( (x+1) * cell_width)))
          {
            if ( (subjective.get_y(i) > (y * cell_height)) && (subjective.get_y(i) < ( (y+1) * cell_height)))
            {
              //pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
              cell_subjective[x][y] = true;
            }
          }
        } 
        /* proposed *****/
        pg.stroke(0, 0, 255);
        pg.fill(0, 0, 255, 95);
        for ( int i = 0; i < proposed.total; i++)
        {
          if ( (proposed.get_x(i) > (x * cell_width)) && (proposed.get_x(i) < ( (x+1) * cell_width)))
          {
            if ( (proposed.get_y(i) > (y * cell_height)) && (proposed.get_y(i) < ( (y+1) * cell_height)))
            {
              //pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
              cell_proposed[x][y] = true;
            }
          }
        }
      }
    }
    pg.endDraw();

    pg.save(path + "-result.png");
    pg.beginDraw();
    

    /* Recall etc caluc */
    int r, n, c;
    double recall;
    double precision;
    double f;

    // subjective vs proposed
    pg.stroke(255, 0, 0);
    pg.fill(255, 0, 0, 50);
    r = n = c = 0;
    for ( int x = 0; x < devide; x++)
    {
      for ( int y = 0; y < devide; y++)
      {
        if (cell_subjective[x][y] == true) c++;
        if (cell_proposed[x][y] == true) n++;
        if (cell_subjective[x][y] == true && cell_proposed[x][y] == true)
        {
          r++;
          pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
        }
      }
    }
    precision = (double)r / n;
    recall = (double)r / c;
    f = (2 * precision * recall) / (precision + recall);
    println("subjective vs proposed");
    println("r = " + r);
    println("n = " + n);
    println("c = " + c);
    println("Precision (r / n) = " + precision);
    println("Recall    (r / c) = " + recall);
    println("f-measure         = " + f);

    // subjective vs saliency
    pg.stroke(0, 255, 0);
    pg.fill(0, 255, 0, 50);
    r = n = c = 0;
    for ( int x = 0; x < devide; x++)
    {
      for ( int y = 0; y < devide; y++)
      {
        if (cell_subjective[x][y] == true) c++;
        if (cell_saliency[x][y] == true) n++;
        if (cell_subjective[x][y] == true && cell_saliency[x][y] == true)
        {
          r++;
          pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
        }
      }
    }
    precision = (double)r / n;
    recall = (double)r / c;
    f = (2 * precision * recall) / (precision + recall);
    println("subjective vs saliency");
    println("r = " + r);
    println("n = " + n);
    println("c = " + c);
    println("Precision (r / n) = " + precision);
    println("Recall    (r / c) = " + recall);
    println("f-measure         = " + f);

    // saliency vs proposed
    pg.stroke(0, 0, 255);
    pg.fill(0, 0, 255, 50);
    r = n = c = 0;
    for ( int x = 0; x < devide; x++)
    {
      for ( int y = 0; y < devide; y++)
      {
        if (cell_saliency[x][y] == true) c++;
        if (cell_proposed[x][y] == true) n++;
        if (cell_saliency[x][y] == true && cell_proposed[x][y] == true)
        {
          r++;
          pg.rect(x * cell_width, y * cell_height, cell_width, cell_height);
        }
      }
    }
    precision = (double)r / n;
    recall = (double)r / c;
    f = (2 * precision * recall) / (precision + recall);
    println("saliency vs proposed");
    println("r = " + r);
    println("n = " + n);
    println("c = " + c);
    println("Precision (r / n) = " + precision);
    println("Recall    (r / c) = " + recall);
    println("f-measure         = " + f);

    pg.endDraw();

    pg.save(path + "-result2.png");

    loop();
  }
}

