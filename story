#!/usr/bin/env python2

import sys
import yaml
import json
import getopt

def help():
	print 'text.sh <option>'
	print ' -h help'
	print ' -f file'
	exit(0)


class Container:

	def __init__(self):
		self.variables = {}

	def set(self, var, value):
		self.variables[var] = value

	def unset(self, var):
		print self.variables
		if var in self.variables:
			del self.variables[var]

	def get(self, var):
		return self.variables[var]

	def contains(self, var):
		return var in self.variables;

	def set_raw(self, vars):
		self.variables = vars

	def get_raw(self):
		return self.variables



class Chapter:

	def __init__(self, data):
		self.pages = data
		self.state = Container()
		self.inventory = Container()
		self.set_current_page('start')

	def get_current_page(self):
		return self.pages[self.page]

	def set_current_page(self, page):
		self.page = page
		self.page_actions = self.page
		return self.pages[self.page]

	def start(self):

		while True:
			page = self.get_current_page()
			print ""
			print ""
			print ""
			print page['description']

			if 'actions' not in page:
				print "The end."
				break

			actions = []
			for action in page['actions']:
				action = self.filter_action(action)
				if action:
					actions.append(action)

			print ""

			for action in actions:
				if 'description' in action:
					print action['description']

			print ""
			i = 1
			for action in actions:
				print " ", i , "-", action['action']
				i = i + 1

			print ""

			sel = raw_input('Choose (number or q=quit, s=save, l=load): ')

			if sel == 'q':
				print "You've chosen to quit... Shame."
				break

			if sel == 's':
				self.save('save.yaml')

			if sel == 'l':
				self.load('save.yaml')

			elif sel.isdigit():

				sel = int(sel)
				sel -= 1
				self.apply_action(list(actions)[sel])

	def filter_action(self, action):

		show = True

		if 'has' in action:
			if not self.inventory.contains(action['has']):
				show = False

		if 'condition' in action:
			if not self.state.contains(action['condition']):
				show = False

		# Filter out actions:
		if 'add' in action:
			if self.inventory.contains(action['add']):
				show = False

		if 'set' in action:
			if self.state.contains(action['set']):
				show = False

		if show:
			return action

		return False

	def apply_action(self, action):

		if 'add' in action:
			self.inventory.set(action['add'], True)

		if 'remove' in action:
			self.inventory.unset(action['add'])

		if 'set' in action:
			self.state.set(action['set'], True)

		if 'unset' in action:
			self.state.unset(action['unset'])

		if 'goto' in action:
			self.set_current_page(action['goto'])

	def get_story_state(self):

		data = {}
		data['page'] = self.page
		data['inventory'] = self.inventory.get_raw()
		data['state'] = self.state.get_raw()

		return data

	def set_story_state(self, data):

		self.page = data['page']
		self.inventory.set_raw(data['inventory'])
		self.state.set_raw(data['state'])

	def save(self, file):
		story_state = self.get_story_state()
		f = open(file, 'w')
		f.write(yaml.dump(story_state, default_flow_style=False))
		f.close()

	def load(self, file):
		f = open(file)
		self.set_story_state(yaml.safe_load(f))
		f.close()


def main(argv):

	file = ''

	try:
		opts, args = getopt.getopt(argv, "f:", ["file="])

	except getopt.GetoptError:
		help()

	for opt, arg in opts:
		if opt == '-h':
			help()
			return
		elif opt in ("-f", "--f"):
			file = arg

	if file == "":
		help()

	f = open(file)
	chapter = Chapter(yaml.safe_load(f))
	chapter.start()
	f.close()



if __name__ == "__main__":

	main(sys.argv[1:])
