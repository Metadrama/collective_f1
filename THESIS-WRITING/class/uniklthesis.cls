% ============================ Main Options =====================================================
\NeedsTeXFormat{LaTeX2e}
%\LoadClass[10pt,a4paper,oneside]{book} 


\LoadClass[11pt,a4paper,oneside]{book} 

%\LoadClass[10pt,a4paper,oneside]{report}  % remember the linespread
%\usepackage{hyperref}%
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}


% ============================ Packages ===================================================== 
\usepackage{graphicx}
\usepackage{meta/atbeginend}
\usepackage{color}
\usepackage{framed}
\usepackage{xcolor}

%\usepackage[top=25mm,left=40mm,bottom=25mm,right=25mm]{geometry}
\usepackage[top=30mm,left=45mm,bottom=30mm,right=30mm]{geometry}

\usepackage{array}
\newcolumntype{L}[1]{>{\raggedright\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{C}[1]{>{\centering\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{R}[1]{>{\raggedleft\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
%USE AS: 
%\begin{tabular}{| c | L{3cm} | C{3cm} | R{3cm} |}
%foo &
%A cell with  \newline manual line breaks & ...


% \orphanpenalty9000
% \widowpenalty=10000
% \clubpenalty=10000
\hyphenpenalty=9999

%\usepackage{makeidx}    % make index package 




\newcommand{\myparskip}{11pt}
\newcommand{\tocparskip}{2pt}
\newcommand{\mylinespread}{1.2}			% bad, bad , bad still needed 
%\newcommand{\mylinespread}{1}			% bad, bad , bad still needed 


 
\widowpenalty9000
\parindent0pt
\parskip\myparskip



	% change the spacings between and before itemize and enumerate  
\newcommand{\mis}{11pt} % my item spacing 
\BeforeBegin{enumerate}{\addtolength{\parskip}{-\mis}}
\AfterEnd{enumerate}{\addtolength{\parskip}{\mis}}
\BeforeBegin{itemize}{\addtolength{\parskip}{-\mis}}
\AfterEnd{itemize}{\addtolength{\parskip}{\mis}}


% ============================ Custom Commands =====================================================
% List of Commands: 
% 	\romanNumbering
%      	\arabicNumbering   
%	\makeTitlePage
% 	\makeSupervisorPage
% 	\makeBibliography
% 	\makeTOC
% 	\makeLOF
% 	\makeLOT
% 	\makeCopyrightsPage
% 	\commonimg
% 	\bodyimg
% --------------------------------------------------------------------------------------------------
\newcommand{\arabicNumbering}{\newpage \pagenumbering{arabic}}	% change to arabic numbering
\newcommand{\romanNumbering}{\newpage \pagenumbering{roman}}	% change to roman numbering

% ============================ Header / footer =====================================================
\usepackage{fancyhdr}
%\fancyfoot{} % clear all header fields
%\fancyfoot[R]{\bfseries \thepage}
		

\pagestyle{fancy}
\fancyhf{} % clear all header and footer fields
\fancyhead[R]{\bfseries \thepage} % except the center
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{unikl}{%
\fancyhf{} % clear all header and footer fields
%\fancyhead[R]{\bfseries \thepage} % except the center
\fancyfoot[R]{\bfseries \thepage} % except the center
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}}

\fancypagestyle{plain}{%
\fancyhf{} % clear all header and footer fields
\fancyfoot[C]{\bfseries \thepage} % except the center
%\fancyhead[C]{{\scriptsize \VthesisTitleShort}}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}}
%	% With this we ensure that the chapter and section
%	% headings are in lowercase.
%	\renewcommand{\headrulewidth}{0.25pt} % changed: 0.25			
%	\renewcommand{\footrulewidth}{0.25pt}
%	\renewcommand{\headrulewidth}{0pt} % TO REMOVE RULE FROM HEADER/FOOTER	
%	\renewcommand{\footrulewidth}{0pt}
%	
%	\renewcommand{\chaptermark}[1]{%
%		\markboth{\footnotesize{#1}}{}}
%	\renewcommand{\sectionmark}[1]{%
%		\markright{\thesection\ #1}
%	}
%	% TO REMOVE HEADER TEXT 
%	\renewcommand{\chaptermark}[1]{\markboth{}{}}
%	\renewcommand{\sectionmark}[1]{\markright{}}
%	
%	\fancyhf{} 				% delete current header and footer
%%	\fancyfoot[RO]{\bfseries\thepage}	% may also make it italic
%	\fancyfoot[LO]{\footnotesize{\VthesisTitleShort}}
%	\fancyfoot[CO]{\bfseries \thepage}
%	
%	% TO REMOVE FOOTER THESIS TITLE
%	\fancyfoot[LO]{}
%	
%	%\fancyhead[LO]{\bfseries\leftmark}
%	\fancyhead[LO]{\leftmark}
%    \fancyhead[LE]{\rightmark}
%    
%	\addtolength{\headheight}{0.5pt} 	% space for the rule
%	\fancyhfoffset[RO]{0in} % to make header width same as text width 
%	\fancypagestyle{plain}{% 		% the contents etc page style 
%		\fancyhead{} 			% get rid of headers on plain pages
%		%\fancyfoot{}			% leave commented for same as 'fancy' style
%		%\fancyhead[LO]{\footnotesize\nouppercase{\bfseries\leftmark}}
%		\fancyhead[LO]{\footnotesize\nouppercase{\leftmark}}
%		%\fancyhead[RO]{\footnotesize\nouppercase{\bfseries\rightmark}}
%	}
%		\fancypagestyle{blank}{% 		% the contents etc page style 
%		\fancyhf{} 			% get rid of headers on plain pages
%		\renewcommand{\headrulewidth}{0pt}			
%		\renewcommand{\footrulewidth}{0pt}
%	}


\usepackage{datetime}
% ========================================================
\newcommand{\makeTitlePage} {
		\begin{titlepage}
		\begin{center}
			\vspace*{0.05in}
			\begin{spacing}{1}
			\LARGE \textbf{\MakeUppercase{\VthesisTitle}}
			\end{spacing}
			\singlespacing
						\vfill \vfill 
%			\\ 
%			\vspace{0.2in} By \\ \vspace{0.2in}  
			\large{\textbf{\MakeUppercase{\VauthorName}}} 
			\vfill
%				\begin{figure}[h]
%					\centering
%					\includegraphics[width=0.35\textwidth]{\commonimg{unikl-logo}}
%				\end{figure}
			\par
			\vfill\vfill 
			\large{
			\linespread{1}
			\VtitlePageNotice
			}
			\par
			\vfill
%			{\large \VdeptName \\ \VuniversityName}\\
%			{\large \VuniversityLocation}
			\par
			\vspace{0.25in}
			{\large \VdateOfSubmission}
			\linespread{\mylinespread}
		\end{center}
	\end{titlepage}
	\addtocounter{page}{1}		% make sure the title page gets a number (invisible)
}% End Title page
%===================================

\newcommand{\makeSubmissionPage}{
		% the supervisor page 
%		\thispagestyle{empty}			% get rid of headers and footers 
		\begin{center}
				{\Large \VthesisTitle}
				\par
				\vfill
%				  \begin{figure}[h]
%				  \centering		    				  						
%				  	\includegraphics[width=0.50\textwidth]{\commonimg{CityLogo}}
%				  \end{figure}
				\vfill
				\par
				{\VsubmissionNote}
				\vfill
				\begin{small}
				\begin{flushleft}
				\par
				\begin{tabbing}		% hack to get the horizontal lines right 
				\makebox[0.5\textwidth]{}  \=   \makebox[0.15\textwidth]{} \= 			\\
         \>  \makebox[0.15\textwidth]{} 
         \includegraphics[scale=0.18]{\imgfolder/nam-sig.pdf}
          \\ 
					Research Scholar:	\> \rule{0.5\textwidth}{0.01ex}					\\
						\> \> {\footnotesize \VauthorName}			\\
					\\ \\ \\  \\
					Supervisor: \>  \rule{0.5\textwidth}{0.1ex}			\\
						\>  \> {\footnotesize \VsupervisorName}			\\
					\\ \\ \\ \\ 		
					\VHOdeptName:	\> \rule{0.5\textwidth}{0.1ex}					\\
						\> \> {\footnotesize \VhodName}			\\
				\end{tabbing}
				\end{flushleft}
				\end{small}
				\vfill
		%		\par				% uncomment if needed
		%		{\Large \VuniversityName}
		%		\par
		%		{\Large \VuniversityLocation}
		%		\par
		%		\vspace{0.25in}
		%		{\Large \VdateOfSubmission}
			\end{center}
}% End Submission page



\newcommand{\makeUniKLApprovalSheet}{
\newpage
\begin{center}

\textbf{\large DECLARATION}
\end{center}

\begin{spacing}{2}

I declare that this report is my original work, and all references have been cited adequately as required by the University.
\end{spacing}
\vspace{200pt}

\begin{spacing}{1.5}
\hspace{-6pt}\begin{tabular}{p{2cm}p{8cm}}		% hack to get the horizontal lines right 
Signature: &  \\ %\rule{0.5\textwidth}{0.1ex} \\ 
Name:& \VauthorName \\
ID Number: & \VauthorID   \\
%Programme:         & \VdegreeName \\
%Place: 			   & \VuniversityName\ - \VdeptName \\
%Title of Thesis:   & \MakeUppercase{\VthesisTitle} \vspace{20pt}\\
%Signature of Candidate: &   \rule{0.5\textwidth}{0.1ex} \\ 
Date:                   &    \VdateOfSubmission \\ 
\end{tabular}
\end{spacing}
%\cfoot{\thepage}
%%%%%%%%%%
\newpage 
\begin{center}

\textbf{\large APPROVAL PAGE}
\end{center}

%\vfill 
%\VapprovalNote
\begin{spacing}{2}
We have supervised and examined this report and verified that it meets the program and University’s requirements for the Bachelor of Information Technology (Hons) in Software Engineering.
\end{spacing}
\vspace{10pt}

%\begin{spacing}{1}
%  \large \textbf{\MakeUppercase{\VthesisTitle}}
%\end{spacing}
%\vfill 
%\textbf{\VauthorName}
%\vfill\vfill 
%\textbf{Approved by:}
%\vfill 

%\rule{0.5\textwidth}{0.1ex}\\
%{\VchairmanName\\ 
%\VchairmanDesignation
%}
%\vfill 
\vspace{100pt}
%\begin{center}
%\rule{0.5\textwidth}{0.1ex}\\
{Signature:  \\
Supervisor: \VsupervisorName \\
Date:  \\
Official Stamp: \\
%Date: \\
%\VsupervisorDesignation \\ 
}
\vspace{50pt}
%\vfill

%\rule{0.5\textwidth}{0.1ex}\\
{Signature : \\
 Accessor: \VaccessorName\\ 
 Date: \\
 Official Stamp:\\  
%\VchairmanDesignation
}

%\end{center}

}

\newcommand{\makeApprovalSheet}{
		% the supervisor page
		\newpage
	\thispagestyle{empty}			% get rid of headers and footers 
		\begin{center}
				\begin{spacing}{1}
							\LARGE \textbf{\MakeUppercase{\VthesisTitle}}
				\end{spacing}
				\par
%				\vfill
%				  \begin{figure}[h]
%				  \centering		    				  						
%				  	\includegraphics[width=0.50\textwidth]{\commonimg{CityLogo}}
%				  \end{figure}
				\vfill
				\par
				{\VapprovalNote}
				\vfill
				\begin{small}
				\begin{flushleft}
				\par
				\begin{spacing}{2.5}
				\begin{tabbing}		% hack to get the horizontal lines right 
				\makebox[0.05\textwidth]{}  \=   \makebox[0.3\textwidth]{} \=  \\
					Chairman University\\
						\> Signature: \> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Name: \> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Designation: 	\> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Institution: 		\> \rule{0.5\textwidth}{0.1ex}					\\ 
						
					\vspace{0.2in} \\
					Dean Institute \\
						\> Signature: \> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Name: \> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Designation: 	\> \rule{0.5\textwidth}{0.1ex}					\\ 
						\> Institution: 		\> \rule{0.5\textwidth}{0.1ex}					\\ 					
						
%					\vspace{0.2in} \\
%					Internal Examiner  \\
%						\> Signature: \> \rule{0.5\textwidth}{0.1ex}					\\ 
%						\> Name: \> \rule{0.5\textwidth}{0.1ex}					\\ 
%						\> Designation: 	\> \rule{0.5\textwidth}{0.1ex}					\\ 
%						\> Institute: 		\> \rule{0.5\textwidth}{0.1ex}					\\ 
				\end{tabbing}
				\end{spacing} 
				\end{flushleft}
				\end{small}
				\vfill
		%		\par				% uncomment if needed
		%		{\Large \VuniversityName}
		%		\par
		%		{\Large \VuniversityLocation}
		%		\par
		%		\vspace{0.25in}
		%		{\Large \VdateOfSubmission}
			\end{center}
}% End approval sheet 


\newcommand{\defineterm}[2]{\textbf{#1:} #2\par}
\newenvironment{Glossary}{%
%\renewcommand{\rightmark}{Glossary}%
\begin{center}
\chapter*{\Large LIST OF ABBREVIATIONS}%
\end{center}
%\pagestyle{empty}%
%\thispagestyle{empty}%
\renewcommand{\leftmark}{Glossary}%
\addcontentsline{toc}{chapter}{List of Abbreviations}% add to tOC    
}{%
\newpage
}


\newenvironment{Annexure}[2]{%
\chapter*{Appendix #1: #2}\addcontentsline{toc}{chapter}{Appendix #1: #2}% add to tOC    
%\pagestyle{fancy}%
%\thispagestyle{plain}%
%\renewcommand{\thechapter}{#1}%
\renewcommand{\leftmark}{#2}%
%\renewcommand{\leftmark}{#2}%
%\renewcommand{\rightmark}{#2}%
%\thispagestyle{empty}%
%\renewcommand{\leftmark}{Glossary}% 
}{%
\newpage
%\thispagestyle{empty}%
}



\newenvironment{abstract}{%
%\newpage\thispagestyle{empty}
%\vspace*{1in}
%\begin{center}
%	{\huge Abstract}  		\\ 
%%	(English) \\
%	\addcontentsline{toc}{chapter}{Abstract (English)}
%	\vspace{0.25in}				
%	\begin{small}
%		\VthesisTitle  			\\ 
%		\vspace{0.13in}			
%		\VauthorName				\\
%		\VuniversityName		\\ 
%		\VauthorEmail 			\\
%		\vspace{0.13in}			
%		\VdateOfSubmission	\\
%	\end{small}
%\end{center}
\begin{center}
{\Large \textbf{ABSTRACT}}\vspace{30pt}\\%
\end{center}
\addcontentsline{toc}{chapter}{Abstract (English)}%
%Abstract of thesis presented to the Senate of \VuniversityName\ Malaysia in
%fulfillment of the requirements for the degree of \VdegreeName

%\MakeUppercase{\VthesisTitle} \\\vspace{6pt}%
%By   
%\\\vspace{6pt}%
%\textbf{\MakeUppercase{\VauthorName}}
%\\\vspace{6pt}%
%\VdateOfSubmission
%\\\vspace{6pt}%
%Chairman: \VchairmanName
%\\\vspace{6pt}%
%PhD Faculty: \VdeptName, \VuniversityName
\par 
}{%
}

\newenvironment{abstractmalay}{%
%\newpage\thispagestyle{empty}
%\vspace*{1in}
%\begin{center}
%	{\huge Abstrak}  		\\ 
%%	(Bhasa Malaysia) \\
%	\addcontentsline{toc}{chapter}{Abstrak (Bahasa Malaysia)}
%	\vspace{0.25in}				
%	\begin{small}
%		\VthesisTitle  			\\ 
%		\vspace{0.13in}			
%		\VauthorName				\\
%		\VuniversityName		\\ 
%		\VauthorEmail 			\\
%		\vspace{0.13in}			
%		\VdateOfSubmission	\\
%	\end{small}
%\end{center}
\begin{center}
{\Large \textbf{ABSTRAK}}\vspace{30pt}\\%
\end{center}
\addcontentsline{toc}{chapter}{Abstrak(Bahasa Malaysia)}%
%{\Huge \textbf{Abstrak (Bahasa Malaysia)}}\vspace{30pt}\\%
%\addcontentsline{toc}{chapter}{Abstrak (Bahasa Malaysia)}%
%Abstrak tesis yang dikemukakan kepada Senat \VuniversityName\ Malaysia sebagai memenuhi keperluan untuk Ijazah \VdegreeName

%\MakeUppercase{\VthesisTitleMalay} \\\vspace{6pt}%
%Oleh  
%\\\vspace{6pt}%
%\textbf{\MakeUppercase{\VauthorName}}
%\\\vspace{6pt}%
%\VdateOfSubmission
%\\\vspace{6pt}%
%Pengerusi: \VchairmanName
%\\\vspace{6pt}%
%Fakulti: \VdeptName, \VuniversityName
\par
}{%
}

\newcommand{\makeBibliography}{%
		\newpage 
		\addcontentsline{toc}{chapter}{\bibname}	% add to TOC - comment to remove add
		\bibliographystyle{\VbibStyle}		
		\bibliography{\VbibName}
}


\newcommand{\makeTOC}{%
	\parskip\tocparskip
	\pagestyle{plain}
	\tableofcontents
	\parskip\myparskip
}

\newcommand{\makeLOF}{%
	\newpage
	\addcontentsline{toc}{chapter}{\listfigurename}		% add to tOC
	\parskip\tocparskip
	\listoffigures	
	\parskip\myparskip
}

\newcommand{\makeLOT}{%
	\newpage
	\addcontentsline{toc}{chapter}{\listtablename}% add to tOC    
	\parskip\tocparskip
	\listoftables
	\parskip\myparskip
}

\newcommand{\makeCopyrightsPage}{
   \newpage
%%	\thispagestyle{empty} 
%	\makebox[\textwidth]{} % hack for vertical alignment -- find better way
\begin{center}
\textbf{\large COPYRIGHT} 
\end{center}
%\vfill 
\begin{spacing}{2}

Declaration of Copyright and Affirmation of Fair Use of Unpublished Research Work as stated below:

 Copyright @ \VdateOfSubmission   \vspace{3pt}  by \VauthorName \vspace{3pt}  (\VauthorID). All rights reserved for \VthesisTitle. 

 No part of this unpublished research may be reproduced, stored in a retrieval system, or transmitted, in any form or by any means, electronic, mechanical, photocopying, recording, or otherwise, without the prior written permission of the copyright holder except as provided below:

 \begin{enumerate}
  \item Others may only use any material contained in or derived from this unpublished research in their writing with due acknowledgment.
  \item MIIT UniKL or its library will have the right to make and transmit copies (print or electronic) for institutional purposes.
  \item The MIIT UniKL’s library will have the rights to make, store in a retrieval system and supply copies of this unpublished research if requested by other universities and research libraries
 \end{enumerate}

\end{spacing}
\vspace{30pt}	

%\VcopyrightNote
%\vfill 
}

\newcommand{\makeDedicationsPage}{
  \newpage %\thispagestyle{empty} 
	\makebox[\textwidth]{} % hack for vertical alignment -- find better way
	\vfill
	\begin{center}
		\VdedicationText
	\end{center}
	\vfill 
}

\newcommand{\makeAcknowledgementsPage}{
   \chapter*{\large ACKNOWLEDGEMENTS}\addcontentsline{toc}{chapter}{Acknowledgements}	 
%	\thispagestyle{empty}
		\VacknowledgementText
}

%\newcommand{\makeCopyrightsPage}{
%	\chapter*{Copyright}\addcontentsline{toc}{chapter}{Copyright}	 
%%	\thispagestyle{empty}
%		\VcopyrightNoteText
%}


\newcommand{\commonimg}[1]{files/commonimgs/{#1}}	% load image from common directory
\newcommand{\bodyimg}[1]{files/bodyimgs/{#1}}		% load image from body images directory


\newcommand{\abrv}[1]{#1}



% ============================ Information Variables Details =====================================================
% list of variables 
%	\authorName
%	\authorID
%	\authorSemester
%	\thesisTitle
%	\thesisTitleShort
%	\supervisorName
%	\universityName
%	\universityLocation
%	\dateOfSubmission
%	\bibName
%	\submissionNote

% ---------------------------------------------------------------------------------------------------------------
\newcommand{\VauthorName}{AUTHOR}
\newcommand{\authorName}[1]{\renewcommand{\VauthorName}{#1}}

\newcommand{\VauthorID}{Author ID}
\newcommand{\authorID}[1]{\renewcommand{\VauthorID}{#1}}

\newcommand{\VauthorEmail}{}
\newcommand{\authorEmail}[1]{\renewcommand{\VauthorEmail}{#1}}

\newcommand{\VauthorSemester}{SEMESTER}
\newcommand{\authorSemester}[1]{\renewcommand{\VauthorSemester}{#1}}

\newcommand{\VdegreeName}{Master of Science (MS) in Software Engineering}
\newcommand{\degreeName}[1]{\renewcommand{\VdegreeName}{#1}}


\newcommand{\VthesisTitle}{Set \emph{thesisTitle} Variable}
\newcommand{\thesisTitle}[1]{\renewcommand{\VthesisTitle}{#1}}

\newcommand{\VthesisTitleMalay}{Set \emph{thesisTitleMalays} Variable}
\newcommand{\thesisTitleMalay}[1]{\renewcommand{\VthesisTitleMalay}{#1}}

\newcommand{\VthesisTitleShort}{\VthesisTitle}
\newcommand{\thesisTitleShort}[1]{\renewcommand{\VthesisTitleShort}{#1}}

\newcommand{\VsupervisorName}{SUPERVISOR}
\newcommand{\supervisorName}[1]{\renewcommand{\VsupervisorName}{#1}}

\newcommand{\VsupervisorDesignation}{SUPERVISOR}
\newcommand{\supervisorDesignation}[1]{\renewcommand{\VsupervisorDesignation}{#1}}


\newcommand{\VaccessorName}{ACCESSOR}
\newcommand{\accessorName}[1]{\renewcommand{\VaccessorName}{#1}}

\newcommand{\VaccessorDesignation}{ACCESSOR DESIGNATION}
\newcommand{\accessorDesignation}[1]{\renewcommand{\VchairmanDesignation}{#1}}


\newcommand{\VdeptName}{Department of Computer Science}
\newcommand{\deptName}[1]{\renewcommand{\VdeptName}{#1}}

\newcommand{\VhodName}{HOD NAME}
\newcommand{\hodName}[1]{\renewcommand{\VhodName}{#1}}

\newcommand{\VHOdeptName}{Head of Computer Science Department}
\newcommand{\HOdeptName}[1]{\renewcommand{\VHOdeptName}{#1}}


\newcommand{\VuniversityName}{City University of Science and Information Technology}
\newcommand{\universityName}[1]{\renewcommand{\VuniversityName}{#1}}
			
\newcommand{\VuniversityLocation}{Peshawar, Pakistan}		
\newcommand{\universityLocation}[1]{\renewcommand{\VuniversityLocation}{#1}}
	
\newcommand{\VdateOfSubmission}{\today}
\newcommand{\dateOfSubmission}[1]{\renewcommand{\VdateOfSubmission}{#1}}


\newcommand{\VsubmissionNote}{This thesis is submitted for fulfillment of requirements for the degree of \VdegreeName\ to the \VdeptName, \VuniversityName\ as on \VdateOfSubmission.} 
\newcommand{\submissionNote}[1]{\renewcommand{\VsubmissionNote}{#1}}



\newcommand{\VtitlePageNotice}{A thesis submitted to the City University of Science and \\ Information Technology in partial fulfillment of \\ requirements for the degree of \par 
Master of Science in Software Engineering} 
\newcommand{\titlePageNotice}[1]{\renewcommand{\VtitlePageNotice}{#1}}

%%%%%%%%%%%%%%%%%%%%%
%\newcommand{\VapprovalNote}{It is certified that we have studied this final thesis by \VauthorName\ in detail. We conclude that this thesis is of sufficient standard to warrant its acceptance by the \VuniversityName\ for the award of the degree of \VdegreeName.  } 
%\newcommand{\approvalNote}[1]{\renewcommand{\VapprovalNote}{#1}}

\newcommand{\VapprovalNote}{We have supervised and examined this report and verified that it meets the program and University’s requirements for the Bachelor of Information Technology (Hons) in Software Engineering.  } 
\newcommand{\approvalNote}[1]{\renewcommand{\VapprovalNote}{#1}}



%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\VcopyrightNote}{COPYRIGHT} 
\newcommand{\copyrightNote}[1]{\renewcommand{\VcopyrightNote}{#1}}

%\newcommand{\VdedicationText}{What? No dedication?} 
%\newcommand{\dedicationText}[1]{\renewcommand{\VdedicationText}{#1}}

\newcommand{\VacknowledgementText}{It's rude to not acknowledge} 
\newcommand{\acknowledgementText}[1]{\renewcommand{\VacknowledgementText}{#1}}


% -- metavariables 

\newcommand{\VbibName}{thesis}		       		 % name of bib database file
\newcommand{\bibName}[1]{\renewcommand{\VbibName}{#1}}

\newcommand{\VbibStyle}{plain}		       		 % name of bib database file
\newcommand{\bibStyle}[1]{\renewcommand{\VbibStyle}{#1}}





% ============================ Captions of Objects =====================================================
\renewcommand{\contentsname}{\Large TABLE OF CONTENTS}
%\renewcommand{\figurename}{Fig.}
%\renewcommand{\tablename}{Tab.}
%\renewcommand{\chaptername}{Chapter}
\renewcommand{\bibname}{References}


% The defaults: 
%\contentsname Contents
%\listfigurename List of Figures
%\listtablename List of Tables
%\bibname Bibliography
%\indexname Index
%\figurename Figure
%\tablename Table
%\partname Part
%\chaptername Chapter
%\appendixname Appendix
%\abstractname Abstract

\newtheorem{theorem}{Theorem}
\newtheorem{acknowledgement}[theorem]{Acknowledgement}
\newtheorem{algorithm}[theorem]{Algorithm}
\newtheorem{axiom}[theorem]{Axiom}
\newtheorem{case}[theorem]{Case}
\newtheorem{claim}[theorem]{Claim}
\newtheorem{conclusion}[theorem]{Conclusion}
\newtheorem{condition}[theorem]{Condition}
\newtheorem{conjecture}[theorem]{Conjecture}
\newtheorem{corollary}[theorem]{Corollary}
\newtheorem{criterion}[theorem]{Criterion}
\newtheorem{definition}[theorem]{Definition}
\newtheorem{example}[theorem]{Example}
\newtheorem{exercise}[theorem]{Exercise}
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{notation}[theorem]{Notation}
\newtheorem{problem}[theorem]{Problem}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{remark}[theorem]{Remark}
\newtheorem{solution}[theorem]{Solution}
\newtheorem{summary}[theorem]{Summary}
\newenvironment{proof}[1][Proof]{\textbf{#1.} }{\ \rule{0.5em}{0.5em}}



% ============================ Margins etc =====================================================

% set margins: Definitely NOT recommended but if your university requires these margins, ... 

% \setlength{\topmargin}{0in}    			% top margin
% \setlength{\topskip}{-1.5in}    			% between header and text
% \setlength{\oddsidemargin}{0.75in} 			% inside margin
% \setlength{\evensidemargin}{0in} 			% outside margin
% \setlength{\textwidth}{5.50in}    			% width of text
% \setlength{\textheight}{8.75in}				% height of main text
 
 
  % \baselineskip{1.66}					% still bad. have to figure out how to use it 
% \setcounter{tocdepth}{2}				% level of headings to show in toc. Currently upto H3
 \linespread{\mylinespread}
 %\setlength{\baselineskip}{1.5\baselineskip}
 

\newcommand*{\AddIndexEntry}[1]{%
%  \par\noindent%
%  \lowercase{
  \def\temp{#1}%
%  }%
  \expandafter\index\expandafter{\temp}%
}

\newcommand{\newterm}[1]{\emph{#1}\AddIndexEntry{#1}}
%\newcommand{\newtermn}[1]{#1\index{\lowercase{#1}}}
\newcommand{\newtermn}[1]{#1\AddIndexEntry{#1}}


\newenvironment{code}{\definecolor{shadecolor}{rgb}{0.97,0.97,0.97}\begin{shaded}}{\end{shaded}}
\newcommand{\texttts}[1]{{\small \texttt{#1}}}
\newcommand{\textttt}[1]{{\scriptsize \texttt{#1}}}

\newenvironment{smalltable}{\begin{small}}{\end{small}}
\newenvironment{smallertable}{\begin{scriptsize}}{\end{scriptsize}}


% pdflscape%
%\begin{landscape}
%\begin{table}
%\centering     % optional, probably makes it look better to have it centered on the page
%\begin{tabular}{....}
%.......
%\end{tabular}
%\end{table}
%\end{landscape}

\setcounter{secnumdepth}{4}
\setcounter{tocdepth}{4}


% HACK FOR IGNORING NUMBERING IN FIGURE CAPTIONS 
\makeatletter
\def\ignorecitefornumbering#1{%
     \begingroup
         \@fileswfalse
         #1%                     % do \cite comand
    \endgroup
}
\makeatother


\newcommand{\surl}[1]{ \scriptsize{\url{#1}} } 



\gdef\inbackmatter{0}
\newcommand{\beginbackmatter}{
\gdef\inbackmatter{1}
}

%\usepackage{avant}
\newcommand{\enablefancychapterhead}{
\usepackage[mono=false,biolinum]{libertine}


\usepackage[explicit]{titlesec}
\newcommand*\chapterlabel{}
\titleformat{\chapter}
  {\gdef\chapterlabel{}
   \normalfont\Huge}
  {\gdef\chapterlabel{\thechapter}}{0pt}
  {%
  \ifnum\thechapter<1%
    \def\chapterfulllabel{##1}%
  \else%
    \ifnum\inbackmatter=1%
      \def\chapterfulllabel{##1}%
    \else%
      \def\chapterfulllabel{Chapter \thechapter: ##1}\fi%
  \fi
  \begin{tikzpicture}[remember picture,overlay]
  \node [anchor=west, yshift=-60mm, 
          fill=black, minimum height=2.5em, minimum width=35mm, 
         ] (cd) at (current page.north west) {};       
%  \node [anchor=east, yshift=-70mm, 
%            fill=black, minimum height=2.5em, minimum width=5mm, 
%           ]  at (current page.north east) {};              
  \node [xshift=45mm, anchor=west, yshift=-60mm, minimum height=2.5em, minimum width=2em, inner xsep=0, inner ysep=0.5em, 
  		fill=white,   
    ] (cl) at (current page.north west) {\textsf{\chapterfulllabel} };
%  \node [below=20mm of cl.south west, inner sep=0, anchor=north west] {\Huge \textbf{#1}};
    \draw [dashed] (cl.south west) -- ++(100em,0); 
%    \draw [dashed] ([yshift=-1pt] cd.north west) -- ++(100em,0); 
%    \node[yshift=-3cm] at (current page.north west)
%      {\begin{tikzpicture}[remember picture, overlay]
%        \draw[fill=green!5] (0,0) rectangle
%          (\paperwidth,3cm);
%        \node[anchor=east,xshift=.9\paperwidth,rectangle,
%              rounded corners=20pt,inner sep=11pt,
%              fill=blue]
%              {\color{white}\chapterlabel#1};
%       \end{tikzpicture}
%      };
   \end{tikzpicture}
  }
}



\newcommand{\makeappendixseperator}{
\clearpage
\thispagestyle{empty}
\vspace*{\fill}
\begin{center} 
\begin{Huge}
\textbf{APPENDIX}
\end{Huge}
\end{center} 
\vfill
\clearpage 
}

\renewcommand{\theenumi}{\alph{enumi}}
\renewcommand{\theenumii}{\roman{enumii}}