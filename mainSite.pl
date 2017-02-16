#!/usr/bin/perl
####
#Lurking Place Studio's Content Management system
#
#Originally Developed by: Tyler Worman tsworman@lurkingplacestudios.com
#
#Please report all bugs to: support@lurkingplacestudios.com
#Last Updated: 3/28/2010
#
# 
#Version 1.0
#
#
#Purpose:
#Enable themeing of plain text html files and dynamically inserted content.
#Minimal use of SQL where possible. We don't really need SQL to serve 4-5 pages that are fairly static.
#
#Open Source, but you may not sell any dirivative of this code. You need not publish any changes you make, but if you do let us know.
#Contact: Support@lurkingplacestudios.com with any questions on licensing.
##

##Includes, basic stuff for web and database.
use CGI;
use DBI;

##Configure database (If you use it) fill in your info here.
$db="dbname";
$host="localhost";
$user="username";
$password="password";  # the password for the database.

##Connect to database:
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
                           $user,
                           $password) 
                           or die "Can't connect to database: $DBI::errstr\n";

##Create a new CGI to get parameterss from.
$co = new CGI;

#Get Parameters from any form that calls this. This gives basic functionality to the page.
#blog id is used to fetch information from the database. You don't need to use it if you don't want.
if ($co ->param()) {
   $func = $co->param('function');
   $bi_id = $co->param('blogID');
   $view = $co->param('view');
   ##Quote all inputs for safety and sanity check if you are building    
   ##queries with them. If not then just bind them as inputs and QQ the  
   ##whole query. This will take care of attempted SQL injection attacks.
   ##$bi_id = $dbh->quote($bi_id);
}

##Set a default, function for the page if the user provides none. Main will be the home page.
if ($func eq "" or $func eq NULL) {
 $func = 'main';
}

##Print CGI headers needed for page to display in the browser.
print "Content-type: text/html\n\n";



##Declare variables we are going to fill into the page.
$body = ''; ##This is the main content for the page
$blogSum = ''; ##In this example this is a summary of all recent blog entries, you could create a similar one for twitter etc...
$picture = ''; ##This is where the pages picture should go if it needs one dynamically.

##SUBSTITUTE YOUR OWN SQL HERE OR DELETE THIS.
##This is used to select blog entries that are going to appear in the blog summary area described above.
##This is useful for dynamic content that will be shown on each page.
  $sql = qq{ SELECT id, title from data_stores Order by date desc Limit 5};
  $sth = $dbh->prepare( $sql );
  $sth->execute();
  $sth->bind_columns( undef, \$id, \$title);
  while( $sth->fetch() ) {
    ##Append HTML for each row to the blogSum string. In this case it's a link with valid blogID's filled in...
    $blogSum .="<p><a href=http://www.yoursite.com/cgi-bin/mainSite.pl?function=blog&view=single&blogID=$id>$title</a></p>\n";
  }
  $sth->finish();

##select proper function of the page based on users input.
if ($func eq 'contact') {
  ## Select contact info from a database entry and display it. This is a sample of a page displayed entirely dynamic.
  $body = '<div class="indent">';
  $sql = qq{ SELECT poster, date, title, content FROM data_stores};
  $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $bi_id);
  $sth->execute();
  $sth->bind_columns( undef, \$bo_poster, \$bo_date, \$bo_title, \$bo_content);
  while( $sth->fetch() ) {
     ##Append the data fetched from the database to the body variable. This is used in the page for the main content.
     $body .= "<p>$bo_title</p><p>$bo_content</p><p>Posted by: $bo_poster on $bo_date</p>";
  }
  $sth->finish();
  $body .= '</div>';
##Use a similar function like below to show dynamic content on a page.
} elsif ($func eq 'blog') {
  ##Single entry blog/news view of a page.
  if ($view eq 'single') {
      $sql = qq{  SELECT poster, date, title, content FROM data_stores WHERE id = ?};
      $sth = $dbh->prepare( $sql );
      $sth->bind_param(1, $bi_id);
      $sth->execute();
      $sth->bind_columns( undef, \$bo_poster, \$bo_date, \$bo_title, \$bo_content);
      while( $sth->fetch() ) {
	  $body .= "<p>$bo_title</p><p>$bo_content</p><p>Posted by: $bo_poster on $bo_date</p>";
      }
      $sth->finish();
  ##View all articles in a specific section or topic...
  } elsif ($view eq 'section') {
      $sql = qq{  SELECT poster, date, title, content FROM data_stores WHERE section = ?  Order by date desc Limit 6};
      $sth = $dbh->prepare( $sql );
      $sth->bind_param(1, $bi_id);
      $sth->execute();
      $sth->bind_columns( undef, \$bo_poster, \$bo_date, \$bo_title, \$bo_content);
      while( $sth->fetch() ) {
	  $body .= "<p>$bo_title</p><p>$bo_content</p><p>Posted by: $bo_poster on $bo_date</p><hr>";
      }
      $sth->finish();
  ##View all posts.
  } elsif ($view eq 'posts') {
      $sql = qq{ SELECT id, date, title from data_stores Order by date desc };
      $sth = $dbh->prepare( $sql );
      $sth->execute();
      $sth->bind_columns( undef, \$bo_id, \$bo_date, \$bo_title);
      while( $sth->fetch() ) {
	  $body .= "<p>$bo_date - <a href=http://www.yoursite.com/cgi-bin/mainSite.pl?function=blog&view=single&blogID=$bo_id>$bo_title</a></p>\n";
      }

      $sth->finish();
  } else {
    ##Some other type of view
  }
##This is the main meat of the non database driven page. You need to edit this section to fill in your page body.
} elsif ($func eq 'main') {
  ## The main page, in this case it's dynamic but yours could be static. Change as you wish...
  $sql = qq{  SELECT content FROM data_stores};
  $sth = $dbh->prepare( $sql );
  $sth->execute();
  $sth->bind_columns( undef, \$bo_content,);
  $body .= '<div class="indent">';
  while( $sth->fetch() ) {
     $body .="$bo_content\n";
  }
  $body .="</div>";
  $sth->finish();
##Actual Static pages that are rendered in the theme.
} elsif ($func eq 'projects') {
   if ($view eq 'samplepage') {
       open(DAT, "../samplepage/index.html");
   } else {
       #The main view for this projects function.
       open(DAT, "../default/index.html");
   }
   #Once the file is opened, read it into the body.
   while (<DAT>) {
       $body = $body . $_;
   }	 
   close(DAT);
} else {
  ##Not a function
  print "Invalid Function!";
  ##exit 1;
}


##This opens and reads in the site template
open(DAT, "../index.template")|| die("Could not open Template!!");

while (<DAT>)
{
  $myTemplate = $myTemplate . $_;
}

##Replace what we need in the template string with our content.
$myTemplate =~ s/CONTENTHERE/$body/g;
$myTemplate =~ s/BLOGENTRYHERE/$blogSum/g;

##Print the now completed template 
print $myTemplate;

#disconnect from database 
$dbh->disconnect or warn "Disconnection error: $DBI::errstr\n";
##End
exit 0;
